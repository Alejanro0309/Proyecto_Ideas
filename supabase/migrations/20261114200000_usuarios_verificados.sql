-- =====================================================================
-- 5 estudiantes y 5 empresas VERIFICADOS para probar la app
-- Crea la fila en auth.users (con contrasena) + usuarios + hija.
-- =====================================================================

-- ---------- 5 ESTUDIANTES ----------
insert into auth.users (id, email, raw_user_meta_data, email_confirmed_at, created_at, updated_at)
values
  ('a1000000-0000-0000-0000-000000000001', 'estudiante1@correo.unimet.edu.ve',
   '{"tipo_cuenta":"estudiante","nombre":"Carlos","apellido":"Mendoza"}'::jsonb, now(), now(), now()),
  ('a1000000-0000-0000-0000-000000000002', 'estudiante2@correo.unimet.edu.ve',
   '{"tipo_cuenta":"estudiante","nombre":"Maria","apellido":"Gonzalez"}'::jsonb, now(), now(), now()),
  ('a1000000-0000-0000-0000-000000000003', 'estudiante3@correo.unimet.edu.ve',
   '{"tipo_cuenta":"estudiante","nombre":"Jose","apellido":"Rodriguez"}'::jsonb, now(), now(), now()),
  ('a1000000-0000-0000-0000-000000000004', 'estudiante4@correo.unimet.edu.ve',
   '{"tipo_cuenta":"estudiante","nombre":"Luisa","apellido":"Hernandez"}'::jsonb, now(), now(), now()),
  ('a1000000-0000-0000-0000-000000000005', 'estudiante5@correo.unimet.edu.ve',
   '{"tipo_cuenta":"estudiante","nombre":"Pedro","apellido":"Torres"}'::jsonb, now(), now(), now())
on conflict (id) do nothing;

insert into auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
values
  ('b1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001',
   '{"email":"estudiante1@correo.unimet.edu.ve","email_verified":true}'::jsonb, 'email', now(), now(), now()),
  ('b1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000002',
   '{"email":"estudiante2@correo.unimet.edu.ve","email_verified":true}'::jsonb, 'email', now(), now(), now()),
  ('b1000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000003',
   '{"email":"estudiante3@correo.unimet.edu.ve","email_verified":true}'::jsonb, 'email', now(), now(), now()),
  ('b1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000004',
   '{"email":"estudiante4@correo.unimet.edu.ve","email_verified":true}'::jsonb, 'email', now(), now(), now()),
  ('b1000000-0000-0000-0000-000000000005', 'a1000000-0000-0000-0000-000000000005', 'a1000000-0000-0000-0000-000000000005',
   '{"email":"estudiante5@correo.unimet.edu.ve","email_verified":true}'::jsonb, 'email', now(), now(), now())
on conflict (provider_id, provider) do nothing;

insert into public.usuarios (id, correo, telefono, tipo_cuenta, creado_en)
values
  ('a1000000-0000-0000-0000-000000000001', 'estudiante1@correo.unimet.edu.ve', '+58 412 555 0001', 'estudiante', now()),
  ('a1000000-0000-0000-0000-000000000002', 'estudiante2@correo.unimet.edu.ve', '+58 412 555 0002', 'estudiante', now()),
  ('a1000000-0000-0000-0000-000000000003', 'estudiante3@correo.unimet.edu.ve', '+58 412 555 0003', 'estudiante', now()),
  ('a1000000-0000-0000-0000-000000000004', 'estudiante4@correo.unimet.edu.ve', '+58 412 555 0004', 'estudiante', now()),
  ('a1000000-0000-0000-0000-000000000005', 'estudiante5@correo.unimet.edu.ve', '+58 412 555 0005', 'estudiante', now())
on conflict (id) do nothing;

insert into public.estudiantes
  (id, tipo_cuenta, nombres, apellidos, cedula, carnet, fecha_nacimiento, trimestre, carrera, verificado)
values
  ('a1000000-0000-0000-0000-000000000001', 'estudiante', 'Carlos', 'Mendoza', '27123456', 'CNE001', '2002-03-15', 6, 'Ingenieria en Computacion', true),
  ('a1000000-0000-0000-0000-000000000002', 'estudiante', 'Maria', 'Gonzalez', '28234567', 'CNE002', '2003-07-22', 4, 'Comunicacion Social', true),
  ('a1000000-0000-0000-0000-000000000003', 'estudiante', 'Jose', 'Rodriguez', '29345678', 'CNE003', '2001-11-08', 8, 'Administracion de Empresas', true),
  ('a1000000-0000-0000-0000-000000000004', 'estudiante', 'Luisa', 'Hernandez', '30456789', 'CNE004', '2004-01-30', 2, 'Diseno Integral', true),
  ('a1000000-0000-0000-0000-000000000005', 'estudiante', 'Pedro', 'Torres', '31567890', 'CNE005', '2000-09-12', 10, 'Contaduria Publica', true)
on conflict (id) do nothing;

-- ---------- 5 EMPRESAS ----------
insert into auth.users (id, email, raw_user_meta_data, email_confirmed_at, created_at, updated_at)
values
  ('a2000000-0000-0000-0000-000000000001', 'empresa1@gmail.com',
   '{"tipo_cuenta":"empresa","empresa_nombre":"Comercial Andina","empresa_tipo":"Comercio"}'::jsonb, now(), now(), now()),
  ('a2000000-0000-0000-0000-000000000002', 'empresa2@gmail.com',
   '{"tipo_cuenta":"empresa","empresa_nombre":"StartUp Lab","empresa_tipo":"Tecnologia"}'::jsonb, now(), now(), now()),
  ('a2000000-0000-0000-0000-000000000003', 'empresa3@gmail.com',
   '{"tipo_cuenta":"empresa","empresa_nombre":"Marca Viva","empresa_tipo":"Servicios"}'::jsonb, now(), now(), now()),
  ('a2000000-0000-0000-0000-000000000004', 'empresa4@gmail.com',
   '{"tipo_cuenta":"empresa","empresa_nombre":"Agencia Norte","empresa_tipo":"Servicios"}'::jsonb, now(), now(), now()),
  ('a2000000-0000-0000-0000-000000000005', 'empresa5@gmail.com',
   '{"tipo_cuenta":"empresa","empresa_nombre":"Revista Epsilon","empresa_tipo":"Educacion"}'::jsonb, now(), now(), now())
on conflict (id) do nothing;

insert into auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
values
  ('b2000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001',
   '{"email":"empresa1@gmail.com","email_verified":true}'::jsonb, 'email', now(), now(), now()),
  ('b2000000-0000-0000-0000-000000000002', 'a2000000-0000-0000-0000-000000000002', 'a2000000-0000-0000-0000-000000000002',
   '{"email":"empresa2@gmail.com","email_verified":true}'::jsonb, 'email', now(), now(), now()),
  ('b2000000-0000-0000-0000-000000000003', 'a2000000-0000-0000-0000-000000000003', 'a2000000-0000-0000-0000-000000000003',
   '{"email":"empresa3@gmail.com","email_verified":true}'::jsonb, 'email', now(), now(), now()),
  ('b2000000-0000-0000-0000-000000000004', 'a2000000-0000-0000-0000-000000000004', 'a2000000-0000-0000-0000-000000000004',
   '{"email":"empresa4@gmail.com","email_verified":true}'::jsonb, 'email', now(), now(), now()),
  ('b2000000-0000-0000-0000-000000000005', 'a2000000-0000-0000-0000-000000000005', 'a2000000-0000-0000-0000-000000000005',
   '{"email":"empresa5@gmail.com","email_verified":true}'::jsonb, 'email', now(), now(), now())
on conflict (provider_id, provider) do nothing;

insert into public.usuarios (id, correo, telefono, tipo_cuenta, creado_en)
values
  ('a2000000-0000-0000-0000-000000000001', 'empresa1@gmail.com', '+58 414 555 0101', 'empresa', now()),
  ('a2000000-0000-0000-0000-000000000002', 'empresa2@gmail.com', '+58 414 555 0102', 'empresa', now()),
  ('a2000000-0000-0000-0000-000000000003', 'empresa3@gmail.com', '+58 414 555 0103', 'empresa', now()),
  ('a2000000-0000-0000-0000-000000000004', 'empresa4@gmail.com', '+58 414 555 0104', 'empresa', now()),
  ('a2000000-0000-0000-0000-000000000005', 'empresa5@gmail.com', '+58 414 555 0105', 'empresa', now())
on conflict (id) do nothing;

insert into public.empresas_nueva (id, tipo_cuenta, tipo_empresa, nombre, logo)
values
  ('a2000000-0000-0000-0000-000000000001', 'empresa', 'Comercio', 'Comercial Andina', null),
  ('a2000000-0000-0000-0000-000000000002', 'empresa', 'Tecnologia', 'StartUp Lab', null),
  ('a2000000-0000-0000-0000-000000000003', 'empresa', 'Servicios', 'Marca Viva', null),
  ('a2000000-0000-0000-0000-000000000004', 'empresa', 'Servicios', 'Agencia Norte', null),
  ('a2000000-0000-0000-0000-000000000005', 'empresa', 'Educacion', 'Revista Epsilon', null)
on conflict (id) do nothing;
