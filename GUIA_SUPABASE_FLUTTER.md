# Guia Supabase + Flutter: Verde Stock

## 1. Crear el proyecto
1. Crea una cuenta en Supabase y selecciona **New project**.
2. Guarda una contraseña segura para PostgreSQL y espera a que el proyecto termine de crear.

## 2. Obtener URL y clave publicable
1. Abre **Project Settings > API**.
2. Copia **Project URL** y **Publishable key** (tambien llamada anon key en SDK antiguos).
3. Introducelas en `lib/core/supabase_config.dart`.
4. Nunca uses ni incluyas `service_role` / secret key.

## 3. Configurar Auth
En **Authentication > Providers**, habilita **Email** y desactiva el registro publico si deseas que solo los administradores creen cuentas.

### Confirmacion y recuperacion
- En **Authentication > URL Configuration**, define la site URL del proyecto.
- Para Android se puede configurar un deep link; en esta version minima, el enlace abre el flujo de recuperacion de Supabase y puede completarse con `updateUser(password:)`.
- Para forzar confirmacion de correo, usa **Authentication > Providers > Email > Confirm email** segun tus necesidades.
- Supabase envia recuperacion real desde **resetPasswordForEmail**.

## 4. Ejecutar SQL
Abre **SQL Editor**, pega el contenido completo de `supabase/setup.sql` y ejecutalo. El script:
- Crea perfiles, categorias, productos y movimientos.
- Inicia todas las tablas vacias.
- Crea un trigger que genera un perfil activo por cada usuario creado en Auth.
- Define RLS y una RPC transaccional `registrar_movimiento`.

No hay datos de demostracion ni credenciales.

## 5. Crear exactamente tres usuarios
En **Authentication > Users > Add user** crea los tres correos manualmente. Indica nombres y apellidos en los metadatos si lo deseas:

```json
{"nombres":"Nombre","apellidos":"Apellido","rol":"admin"}
```

El trigger crea el perfil con rol `viewer` si no se indica otro rol valido. Antes de asignar permisos, asigna:

```sql
update public.perfiles
set rol = 'admin', activo = true
where id = (select id from auth.users where email = 'correo1@ejemplo.com');

update public.perfiles
set rol = 'editor', activo = true
where id = (select id from auth.users where email = 'correo2@ejemplo.com');

update public.perfiles
set rol = 'viewer', activo = true
where id = (select id from auth.users where email = 'correo3@ejemplo.com');
```

Los roles `admin` y `editor` crean, editan y registran movimientos. `viewer` solo consulta.

## 6. Verificar RLS
- Comprueba **Authentication** y **Table Editor**.
- Una sesion anonima no puede leer las tablas.
- Un usuario autenticado puede leer solo datos permitidos por las politicas.
- Los usuarios sin rol editor/admin no pueden cambiar productos, categorias ni movimientos.

## 7. Ejecutar Flutter
```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```
El destino es Android. Introduce las credenciales publicas antes de ejecutar.

## 8. Uso de la aplicacion
- **Inicio:** resumen y ultimos movimientos.
- **Productos:** buscar, filtrar y crear, editar o desactivar productos.
- **Categorias:** crear, editar y desactivar categorias. Una categoria con productos no debe eliminarse fisicamente.
- **Movimientos:** entradas y salidas atomicas.
- **Perfil:** cerrar sesion real.

El stock inicial solo se registra al crear el producto. Los cambios posteriores deben hacerse desde Movimientos para conservar la trazabilidad. La RPC actualiza stock e inserta el movimiento en una sola transaccion.

## 9. Espacio reservado para imagenes
Las tarjetas de productos mantienen un area visual reservada separada del contenido. Esta area permanece vacia en esta version y no usa base de datos, almacenamiento local, Supabase Storage, iconos ni placeholders. Se preparara para una futura incorporacion sin redisenar las tarjetas.

## 10. Verificacion
```sql
select count(*) from public.categorias;
select count(*) from public.productos;
select count(*) from public.movimientos;
select id, rol, activo from public.perfiles;
```
Las tres primeras consultas deben ser cero antes de crear datos manualmente.
