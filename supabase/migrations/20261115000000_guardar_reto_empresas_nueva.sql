-- =====================================================================
-- Arreglo: `guardar_reto` consultaba `public.perfiles` para deducir el rol,
-- pero el trigger de alta de usuarios (20261114300000) ya no escribe en
-- `perfiles`: las cuentas nuevas nacen en `public.usuarios` +
-- `public.empresas_nueva`. Toda empresa registrada a partir de ese cambio
-- recibia 'SIN_PERMISO' y no podia crear retos.
--
-- Se anade un fallback: si no hay fila en `perfiles`, el rol se deduce de
-- `empresas_nueva` y los datos de contacto de `usuarios`.
-- =====================================================================

create or replace function public.guardar_reto(p_reto_id uuid, p_datos jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$

declare
  v_uid uuid := (select auth.uid());
  v_rol text;
  v_nombre text;
  v_correo text;
  v_tel text;
  v_reto public.retos%rowtype;
  v_bloqueado boolean := false;
  v_publicar boolean := coalesce((p_datos->>'publicar')::boolean, false);
  v_titulo text := trim(coalesce(p_datos->>'titulo', ''));
  v_desc text := coalesce(p_datos->>'descripcion', '');
  v_area smallint;
  v_duracion integer := coalesce((p_datos->>'duracion_dias')::integer, 3);
  v_pago integer := coalesce((p_datos->>'presupuesto_usd')::integer, 1);
  v_cupos integer := coalesce((p_datos->>'cupos')::integer, 1);
  v_fecha date := coalesce((p_datos->>'fecha_limite')::date, current_date + 14);
  v_entregables text[];
  v_n_preg integer := jsonb_array_length(coalesce(p_datos->'preguntas', '[]'::jsonb));
  v_id uuid;
begin
  if v_uid is null then raise exception 'NO_AUTENTICADO'; end if;

  select p.rol, p.nombre, p.correo, p.telefono
    into v_rol, v_nombre, v_correo, v_tel
  from public.perfiles p where p.id = v_uid;
  if v_rol is null then
    -- Usuario nuevo: el trigger de alta (20261114300000) ya no escribe en
    -- `perfiles`, sino en `usuarios` + `empresas_nueva`. Se deduce el rol
    -- de ahi para no devolver 'SIN_PERMISO' a las empresas registradas.
    select 'empresa', e.nombre, u.correo, nullif(u.telefono, '')
      into v_rol, v_nombre, v_correo, v_tel
      from public.empresas_nueva e
      join public.usuarios u on u.id = e.id
      where e.id = v_uid;
  end if;

  if v_rol is null or v_rol not in ('empresa', 'admin') then
    raise exception 'SIN_PERMISO';
  end if;

  if p_reto_id is not null then
    select * into v_reto from public.retos r where r.id = p_reto_id;
    if not found then raise exception 'RETO_NO_ENCONTRADO'; end if;
    if not (v_rol = 'admin' or coalesce(v_reto.empresa_id = v_uid, false)) then
      raise exception 'SIN_PERMISO';
    end if;
    if v_reto.estado in ('cerrado', 'completado') then
      raise exception 'RETO_CERRADO';
    end if;
    v_bloqueado := exists (
      select 1 from public.reto_aceptaciones x where x.reto_id = p_reto_id
    );
  end if;

  if v_cupos not between 1 and 10 then raise exception 'CUPOS_INVALIDOS'; end if;

  if not v_bloqueado then
    select a.id into v_area from public.areas a where a.slug = p_datos->>'area_slug';

    select coalesce(array_agg(trim(e)) filter (where trim(e) <> ''), '{}')
      into v_entregables
    from jsonb_array_elements_text(coalesce(p_datos->'entregables', '[]'::jsonb)) as t(e);

    if length(v_titulo) < 5 or length(v_titulo) > 120 then raise exception 'TITULO_INVALIDO'; end if;
    if length(v_desc) > 2000 then raise exception 'DESCRIPCION_INVALIDA'; end if;
    if v_area is null then raise exception 'AREA_INVALIDA'; end if;
    if v_duracion not between 1 and 7 then raise exception 'DURACION_INVALIDA'; end if;
    if v_pago < 1 or v_pago > 100000 then raise exception 'PAGO_INVALIDO'; end if;
    if cardinality(v_entregables) > 8
       or exists (select 1 from unnest(v_entregables) u where length(u) > 140) then
      raise exception 'ENTREGABLES_INVALIDOS';
    end if;
    if v_n_preg > 3 then raise exception 'PREGUNTAS_INVALIDAS'; end if;

    if v_publicar then
      if v_fecha < current_date then raise exception 'FECHA_INVALIDA'; end if;
      if cardinality(v_entregables) < 1 then raise exception 'ENTREGABLES_INVALIDOS'; end if;
      if v_n_preg <> 3 then raise exception 'PREGUNTAS_INVALIDAS'; end if;
    end if;
  end if;

  if p_reto_id is null then
    insert into public.retos
      (empresa_id, empresa_nombre, titulo, descripcion, entregables, area_id,
       duracion_dias, presupuesto_usd, fecha_limite, estado, cupos)
    values
      (v_uid, coalesce(v_nombre, 'Empresa'), v_titulo, v_desc, v_entregables, v_area,
       v_duracion, v_pago, v_fecha,
       case when v_publicar then 'publicado' else 'borrador' end, v_cupos)
    returning id into v_id;
  else
    v_id := p_reto_id;
    if v_bloqueado then
      v_cupos := coalesce((p_datos->>'cupos')::integer, v_reto.cupos);
      if v_cupos < (select count(*) from public.reto_aceptaciones x
                    where x.reto_id = v_id and x.estado <> 'cancelado') then
        raise exception 'CUPOS_INVALIDOS';
      end if;
      update public.retos
      set descripcion = coalesce(p_datos->>'descripcion', v_reto.descripcion),
          fecha_limite = coalesce((p_datos->>'fecha_limite')::date, v_reto.fecha_limite),
          cupos = v_cupos
      where id = v_id;
    else
      update public.retos
      set titulo = v_titulo, descripcion = v_desc, entregables = v_entregables,
          area_id = v_area, duracion_dias = v_duracion, presupuesto_usd = v_pago,
          fecha_limite = v_fecha, cupos = v_cupos,
          estado = case when v_publicar and estado = 'borrador'
                        then 'publicado' else estado end
      where id = v_id;
    end if;
  end if;

  if not v_bloqueado then
    delete from public.reto_habilidades where reto_id = v_id;
    insert into public.reto_habilidades (reto_id, habilidad_id)
    select v_id, h.id
    from public.habilidades h
    where h.slug in (
      select jsonb_array_elements_text(coalesce(p_datos->'habilidades', '[]'::jsonb))
    )
    limit 8;

    delete from public.reto_preguntas where reto_id = v_id;
    insert into public.reto_preguntas (reto_id, orden, tipo, enunciado, opciones)
    select v_id, q.ord::smallint, q.elem->>'tipo', trim(q.elem->>'enunciado'),
           case when q.elem->>'tipo' = 'opcion' then (
                  select array_agg(trim(o))
                  from jsonb_array_elements_text(q.elem->'opciones') as t2(o)
                  where trim(o) <> '')
                else null end
    from jsonb_array_elements(coalesce(p_datos->'preguntas', '[]'::jsonb))
         with ordinality as q(elem, ord);

    insert into public.reto_contactos (reto_id, correo, telefono)
    values (v_id, v_correo, v_tel)
    on conflict (reto_id) do update
      set correo = excluded.correo, telefono = excluded.telefono;
  end if;

  return v_id;
exception
  when invalid_text_representation
    or invalid_datetime_format
    or datetime_field_overflow then
    raise exception 'DATOS_INVALIDOS';
end;
$$;

revoke all on function public.guardar_reto(uuid, jsonb) from public, anon;
grant execute on function public.guardar_reto(uuid, jsonb) to authenticated;
