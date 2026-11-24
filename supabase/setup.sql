create extension if not exists pgcrypto;

create table if not exists public.perfiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nombres text not null default '',
  apellidos text not null default '',
  rol text not null default 'viewer' check (rol in ('admin','editor','viewer')),
  activo boolean not null default true,
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);

create table if not exists public.categorias (
  id uuid primary key default gen_random_uuid(),
  nombre text not null,
  descripcion text,
  activo boolean not null default true,
  creado_por uuid not null references auth.users(id),
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now(),
  unique (nombre)
);
create unique index if not exists categorias_nombre_unico on public.categorias(lower(nombre));

create table if not exists public.productos (
  id uuid primary key default gen_random_uuid(),
  categoria_id uuid not null references public.categorias(id),
  codigo text,
  nombre text not null,
  descripcion text,
  unidad text not null default 'unidad',
  precio numeric(12,2),
  stock integer not null default 0 check (stock >= 0),
  stock_minimo integer not null default 0 check (stock_minimo >= 0),
  imagen_local_path text,
  activo boolean not null default true,
  creado_por uuid not null references auth.users(id),
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now()
);
create unique index if not exists productos_codigo_unico on public.productos(codigo) where codigo is not null;
create index if not exists productos_categoria_idx on public.productos(categoria_id);
create index if not exists productos_nombre_idx on public.productos(lower(nombre));

create table if not exists public.movimientos (
  id uuid primary key default gen_random_uuid(),
  producto_id uuid not null references public.productos(id),
  usuario_id uuid not null references auth.users(id),
  tipo text not null check (tipo in ('ENTRADA','SALIDA')),
  cantidad integer not null check (cantidad > 0),
  stock_anterior integer not null check (stock_anterior >= 0),
  stock_resultante integer not null check (stock_resultante >= 0),
  motivo text,
  creado_en timestamptz not null default now()
);
create index if not exists movimientos_producto_idx on public.movimientos(producto_id);
create index if not exists movimientos_fecha_idx on public.movimientos(creado_en desc);

create or replace function public.actualizar_timestamp()
returns trigger language plpgsql set search_path = public as $$
begin
  new.actualizado_en = now();
  return new;
end $$;

drop trigger if exists perfiles_actualizado on public.perfiles;
create trigger perfiles_actualizado before update on public.perfiles
for each row execute function public.actualizar_timestamp();
drop trigger if exists categorias_actualizada on public.categorias;
create trigger categorias_actualizada before update on public.categorias
for each row execute function public.actualizar_timestamp();
drop trigger if exists productos_actualizado on public.productos;
create trigger productos_actualizado before update on public.productos
for each row execute function public.actualizar_timestamp();

create or replace function public.perfil_actual()
returns public.perfiles language sql stable security definer set search_path = public as $$
  select * from public.perfiles where id = auth.uid()
$$;

create or replace function public.puede_editar()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.perfiles
    where id = auth.uid() and activo and rol in ('admin','editor')
  )
$$;

create or replace function public.crear_perfil_usuario()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.perfiles(id, nombres, apellidos, rol, activo)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'nombres',''),
    coalesce(new.raw_user_meta_data->>'apellidos',''),
    coalesce(new.raw_user_meta_data->>'rol','viewer'),
    true
  )
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute function public.crear_perfil_usuario();

alter table public.perfiles enable row level security;
alter table public.categorias enable row level security;
alter table public.productos enable row level security;
alter table public.movimientos enable row level security;

drop policy if exists "perfil propio" on public.perfiles;
create policy "perfil propio" on public.perfiles for select
using (id = auth.uid());
drop policy if exists "solo admin actualiza perfiles" on public.perfiles;
create policy "solo admin actualiza perfiles" on public.perfiles for update
using (exists(select 1 from public.perfiles p where p.id=auth.uid() and p.activo and p.rol='admin'))
with check (exists(select 1 from public.perfiles p where p.id=auth.uid() and p.activo and p.rol='admin'));

drop policy if exists "leer categorias autenticado" on public.categorias;
create policy "leer categorias autenticado" on public.categorias for select to authenticated
using (exists(select 1 from public.perfiles p where p.id=auth.uid() and p.activo));
drop policy if exists "editar categorias autorizado" on public.categorias;
create policy "editar categorias autorizado" on public.categorias for all to authenticated
using (public.puede_editar()) with check (public.puede_editar());

drop policy if exists "leer productos autenticado" on public.productos;
create policy "leer productos autenticado" on public.productos for select to authenticated
using (exists(select 1 from public.perfiles p where p.id=auth.uid() and p.activo));
drop policy if exists "editar productos autorizado" on public.productos;
create policy "editar productos autorizado" on public.productos for all to authenticated
using (public.puede_editar()) with check (public.puede_editar());

drop policy if exists "leer movimientos autenticado" on public.movimientos;
create policy "leer movimientos autenticado" on public.movimientos for select to authenticated
using (exists(select 1 from public.perfiles p where p.id=auth.uid() and p.activo));
drop policy if exists "crear movimientos autorizado" on public.movimientos;
create policy "crear movimientos autorizado" on public.movimientos for insert to authenticated
with check (public.puede_editar() and usuario_id=auth.uid());

create or replace function public.registrar_movimiento(
  p_producto_id uuid,
  p_tipo text,
  p_cantidad integer,
  p_motivo text default null
) returns public.movimientos language plpgsql security definer set search_path = public as $$
declare
  v_usuario uuid := auth.uid();
  v_anterior integer;
  v_resultante integer;
  v_movimiento public.movimientos;
begin
  if v_usuario is null or not public.puede_editar() then
    raise exception 'No autorizado';
  end if;
  if p_cantidad is null or p_cantidad <= 0 then
    raise exception 'La cantidad debe ser mayor que cero';
  end if;
  if p_tipo not in ('ENTRADA','SALIDA') then
    raise exception 'Tipo de movimiento invalido';
  end if;
  select stock into v_anterior from public.productos
  where id=p_producto_id and activo=true for update;
  if v_anterior is null then
    raise exception 'Producto no encontrado';
  end if;
  if p_tipo='ENTRADA' then
    v_resultante := v_anterior + p_cantidad;
  else
    v_resultante := v_anterior - p_cantidad;
    if v_resultante < 0 then
      raise exception 'La salida supera el stock disponible';
    end if;
  end if;
  update public.productos set stock=v_resultante, actualizado_en=now()
  where id=p_producto_id;
  insert into public.movimientos(producto_id,usuario_id,tipo,cantidad,stock_anterior,stock_resultante,motivo)
  values(p_producto_id,v_usuario,p_tipo,p_cantidad,v_anterior,v_resultante,nullif(trim(p_motivo),''))
  returning * into v_movimiento;
  return v_movimiento;
end $$;

revoke all on function public.registrar_movimiento(uuid,text,integer,text) from public;
grant execute on function public.registrar_movimiento(uuid,text,integer,text) to authenticated;
