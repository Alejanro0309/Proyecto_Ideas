-- Función con permisos elevados para verificar un carnet y asociarlo al usuario autenticado.
-- Valida que el usuario esté autenticado y que el carnet no pertenezca a otro estudiante.
create or replace function public.verificar_carnet(p_codigo text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_codigo_limpio text;
  v_duplicado boolean;
  v_nombre text;
  v_apellido text;
begin
  -- 1. Obtener ID del usuario autenticado
  v_user_id := auth.uid();
  if v_user_id is null then
    return jsonb_build_object(
      'success', false,
      'error', 'unauthorized',
      'message', 'Debes iniciar sesión para verificar tu carnet.'
    );
  end if;

  -- 2. Limpiar y validar código
  v_codigo_limpio := upper(trim(coalesce(p_codigo, '')));
  if length(v_codigo_limpio) < 5 then
    return jsonb_build_object(
      'success', false,
      'error', 'invalid_code',
      'message', 'El código del carnet no tiene un formato válido.'
    );
  end if;

  -- 3. Regla anti-fraude: comprobar si otro usuario ya registró este carnet
  select exists(
    select 1 from public.perfiles
    where carnet_codigo = v_codigo_limpio
      and id <> v_user_id
  ) into v_duplicado;

  if v_duplicado then
    return jsonb_build_object(
      'success', false,
      'error', 'already_registered',
      'message', 'Este carnet ya se encuentra registrado y verificado por otro estudiante.'
    );
  end if;

  -- 4. Actualizar el perfil del estudiante
  update public.perfiles
  set
    carnet_codigo = v_codigo_limpio,
    verificado = true
  where id = v_user_id
  returning nombre, apellido into v_nombre, v_apellido;

  return jsonb_build_object(
    'success', true,
    'carnet_codigo', v_codigo_limpio,
    'nombre', coalesce(v_nombre, 'Estudiante'),
    'apellido', coalesce(v_apellido, 'Unimet'),
    'message', '¡Carnet verificado con éxito en la Unimet!'
  );
end;
$$;

-- Permitir a los usuarios autenticados llamar a esta función
grant execute on function public.verificar_carnet(text) to authenticated;

