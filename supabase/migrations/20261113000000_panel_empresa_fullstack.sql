-- =====================================================================
-- panel_empresa_fullstack.md (sección 4)
-- Postulaciones, cupos, preguntas, panel de empresa y revisión con
-- calificación. Ejecutar COMPLETO en el SQL Editor de Supabase.
-- =====================================================================

-- =====================================================================
-- 4.1 Tablas y columnas
-- =====================================================================
alter table public.retos
  add column if not exists cupos smallint not null default 1
    check (cupos between 1 and 10);

alter table public.reto_aceptaciones
  add column if not exists vence_en date,
  add column if not exists calificacion smallint
    check (calificacion between 1 and 5),
  add column if not exists comentario_evaluacion text
    check (comentario_evaluacion is null or length(comentario_evaluacion) <= 500);

update public.reto_aceptaciones x
set vence_en = (x.aceptado_en at time zone 'utc')::date + r.duracion_dias
from public.retos r
where r.id = x.reto_id and x.vence_en is null;

create table if not exists public.reto_preguntas (
  id uuid primary key default gen_random_uuid(),
  reto_id uuid not null references public.retos(id) on delete cascade,
  orden smallint not null check (orden between 1 and 3),
  tipo text not null check (tipo in ('opcion', 'texto')),
  enunciado text not null check (length(trim(enunciado)) between 5 and 200),
  opciones text[] check (opciones is null or cardinality(opciones) between 2 and 6),
  unique (reto_id, orden),
  check ((tipo = 'opcion' and opciones is not null)
      or (tipo = 'texto' and opciones is null))
);

create table if not exists public.reto_postulaciones (
  id uuid primary key default gen_random_uuid(),
  reto_id uuid not null references public.retos(id) on delete cascade,
  estudiante_id uuid not null references auth.users(id) on delete cascade,
  estado text not null default 'pendiente'
    check (estado in ('pendiente', 'seleccionada', 'descartada', 'retirada')),
  respuestas jsonb not null default '[]'::jsonb,
  creado_en timestamptz not null default now(),
  decidido_en timestamptz,
  unique (reto_id, estudiante_id)
);

create index if not exists reto_postulaciones_reto_idx
  on public.reto_postulaciones (reto_id, estado);
create index if not exists reto_postulaciones_estudiante_idx
  on public.reto_postulaciones (estudiante_id);

insert into public.reto_postulaciones
  (reto_id, estudiante_id, estado, respuestas, creado_en, decidido_en)
select x.reto_id, x.estudiante_id, 'seleccionada', '[]'::jsonb,
       x.aceptado_en, x.aceptado_en
from public.reto_aceptaciones x
on conflict (reto_id, estudiante_id) do nothing;

-- =====================================================================
-- 4.2 Seguridad (RLS)
-- =====================================================================
alter table public.reto_preguntas enable row level security;
alter table public.reto_postulaciones enable row level security;

drop policy if exists "preguntas_admin" on public.reto_preguntas;
create policy "preguntas_admin" on public.reto_preguntas
  for all to authenticated
  using (public.es_admin()) with check (public.es_admin());

drop policy if exists "postulaciones_propias" on public.reto_postulaciones;
create policy "postulaciones_propias" on public.reto_postulaciones
  for select to authenticated
  using (estudiante_id = (select auth.uid()) or public.es_admin());

create or replace function public.es_dueno_reto(p_reto_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.es_admin()
      or exists (
        select 1 from public.retos r
        where r.id = p_reto_id and r.empresa_id = (select auth.uid())
      );
$$;

revoke all on function public.es_dueno_reto(uuid) from public, anon;
grant execute on function public.es_dueno_reto(uuid) to authenticated;

-- =====================================================================
-- 4.3 Empresa: crear y editar un reto
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

-- =====================================================================
-- 4.4 Empresa: publicar, cerrar y eliminar
-- =====================================================================
create or replace function public.publicar_reto(p_reto_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_estado text;
  v_entregables integer;
  v_fecha date;
begin
  if (select auth.uid()) is null then raise exception 'NO_AUTENTICADO'; end if;
  if not public.es_dueno_reto(p_reto_id) then raise exception 'SIN_PERMISO'; end if;

  select r.estado, coalesce(array_length(r.entregables, 1), 0), r.fecha_limite
    into v_estado, v_entregables, v_fecha
  from public.retos r where r.id = p_reto_id;

  if not found then raise exception 'RETO_NO_ENCONTRADO'; end if;
  if v_estado <> 'borrador' then raise exception 'ESTADO_INVALIDO'; end if;
  if v_entregables < 1 then raise exception 'ENTREGABLES_INVALIDOS'; end if;
  if (select count(*) from public.reto_preguntas q where q.reto_id = p_reto_id) <> 3 then
    raise exception 'PREGUNTAS_INVALIDAS';
  end if;
  if v_fecha < current_date then raise exception 'FECHA_INVALIDA'; end if;

  update public.retos set estado = 'publicado' where id = p_reto_id;
end;
$$;

create or replace function public.cerrar_reto(p_reto_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null then raise exception 'NO_AUTENTICADO'; end if;
  if not public.es_dueno_reto(p_reto_id) then raise exception 'SIN_PERMISO'; end if;

  update public.retos set estado = 'cerrado'
  where id = p_reto_id and estado in ('borrador', 'publicado');
  if not found then raise exception 'ESTADO_INVALIDO'; end if;
end;
$$;

create or replace function public.eliminar_reto(p_reto_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null then raise exception 'NO_AUTENTICADO'; end if;
  if not public.es_dueno_reto(p_reto_id) then raise exception 'SIN_PERMISO'; end if;

  if exists (select 1 from public.reto_aceptaciones x where x.reto_id = p_reto_id)
     or exists (select 1 from public.reto_postulaciones p
                where p.reto_id = p_reto_id and p.estado <> 'retirada') then
    raise exception 'RETO_CON_ACTIVIDAD';
  end if;

  delete from public.retos where id = p_reto_id;
  if not found then raise exception 'RETO_NO_ENCONTRADO'; end if;
end;
$$;

revoke all on function public.publicar_reto(uuid) from public, anon;
revoke all on function public.cerrar_reto(uuid) from public, anon;
revoke all on function public.eliminar_reto(uuid) from public, anon;
grant execute on function public.publicar_reto(uuid) to authenticated;
grant execute on function public.cerrar_reto(uuid) to authenticated;
grant execute on function public.eliminar_reto(uuid) to authenticated;

-- =====================================================================
-- 4.5 Empresa: listas y detalle
-- =====================================================================
create or replace function public.mis_retos_empresa()
returns table (
  reto_id uuid, titulo text, area_nombre text, estado text, cupos smallint,
  presupuesto_usd integer, duracion_dias smallint, fecha_limite date,
  creado_en timestamptz,
  candidatos_pendientes bigint, en_curso bigint, en_revision bigint,
  completados bigint
)
language sql
stable
security definer
set search_path = ''
as $$
  select r.id, r.titulo, a.nombre, r.estado, r.cupos, r.presupuesto_usd,
         r.duracion_dias, r.fecha_limite, r.creado_en,
         (select count(*) from public.reto_postulaciones p
           where p.reto_id = r.id and p.estado = 'pendiente'),
         (select count(*) from public.reto_aceptaciones x
           where x.reto_id = r.id and x.estado = 'aceptado'),
         (select count(*) from public.reto_aceptaciones x
           where x.reto_id = r.id and x.estado = 'entregado'),
         (select count(*) from public.reto_aceptaciones x
           where x.reto_id = r.id and x.estado = 'completado')
  from public.retos r
  join public.areas a on a.id = r.area_id
  where public.es_admin() or r.empresa_id = (select auth.uid())
  order by r.creado_en desc;
$$;

create or replace function public.detalle_reto_empresa(p_reto_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_res jsonb;
begin
  if (select auth.uid()) is null then raise exception 'NO_AUTENTICADO'; end if;
  if not public.es_dueno_reto(p_reto_id) then raise exception 'SIN_PERMISO'; end if;

  select jsonb_build_object(
    'id', r.id,
    'titulo', r.titulo,
    'descripcion', r.descripcion,
    'entregables', to_jsonb(r.entregables),
    'area_slug', a.slug,
    'area_nombre', a.nombre,
    'duracion_dias', r.duracion_dias,
    'presupuesto_usd', r.presupuesto_usd,
    'fecha_limite', r.fecha_limite,
    'estado', r.estado,
    'cupos', r.cupos,
    'habilidades', coalesce((
      select jsonb_agg(h.slug order by h.slug)
      from public.reto_habilidades rh
      join public.habilidades h on h.id = rh.habilidad_id
      where rh.reto_id = r.id), '[]'::jsonb),
    'preguntas', coalesce((
      select jsonb_agg(jsonb_build_object(
               'orden', q.orden, 'tipo', q.tipo,
               'enunciado', q.enunciado, 'opciones', to_jsonb(q.opciones))
             order by q.orden)
      from public.reto_preguntas q where q.reto_id = r.id), '[]'::jsonb),
    'bloqueado', exists (
      select 1 from public.reto_aceptaciones x where x.reto_id = r.id)
  )
  into v_res
  from public.retos r
  join public.areas a on a.id = r.area_id
  where r.id = p_reto_id;

  if v_res is null then raise exception 'RETO_NO_ENCONTRADO'; end if;
  return v_res;
end;
$$;

create or replace function public.candidatos_reto(p_reto_id uuid)
returns table (
  postulacion_id uuid, estudiante_nombre text, estudiante_apellido text,
  carnet_registrado boolean, retos_completados bigint,
  calificacion_promedio numeric, estado text, respuestas jsonb,
  creado_en timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select p.id, pf.nombre, pf.apellido, (pf.cedula is not null),
         (select count(*) from public.reto_aceptaciones x
           where x.estudiante_id = p.estudiante_id and x.estado = 'completado'),
         (select round(avg(x.calificacion), 1) from public.reto_aceptaciones x
           where x.estudiante_id = p.estudiante_id and x.calificacion is not null),
         p.estado, p.respuestas, p.creado_en
  from public.reto_postulaciones p
  join public.perfiles pf on pf.id = p.estudiante_id
  where p.reto_id = p_reto_id
    and p.estado <> 'retirada'
    and public.es_dueno_reto(p_reto_id)
  order by case p.estado when 'pendiente' then 0 when 'seleccionada' then 1 else 2 end,
           p.creado_en;
$$;

create or replace function public.participantes_reto(p_reto_id uuid)
returns table (
  aceptacion_id uuid, estudiante_nombre text, estudiante_apellido text,
  estudiante_correo text, estado text, marcados integer, total integer,
  vence_en date, aceptado_en timestamptz, enviado_en timestamptz,
  completado_en timestamptz, entregables text[], items_marcados smallint[],
  entrega_enlace text, entrega_nota text, calificacion smallint,
  comentario_evaluacion text
)
language sql
stable
security definer
set search_path = ''
as $$
  select x.id, pf.nombre, pf.apellido, pf.correo, x.estado,
         coalesce(cardinality(x.items_marcados), 0),
         coalesce(array_length(r.entregables, 1), 0),
         x.vence_en, x.aceptado_en, x.enviado_en, x.completado_en,
         r.entregables, x.items_marcados, x.entrega_enlace, x.entrega_nota,
         x.calificacion, x.comentario_evaluacion
  from public.reto_aceptaciones x
  join public.retos r on r.id = x.reto_id
  join public.perfiles pf on pf.id = x.estudiante_id
  where x.reto_id = p_reto_id
    and x.estado <> 'cancelado'
    and public.es_dueno_reto(p_reto_id)
  order by case x.estado when 'entregado' then 0 when 'aceptado' then 1 else 2 end,
           x.enviado_en nulls last;
$$;

revoke all on function public.mis_retos_empresa() from public, anon;
revoke all on function public.detalle_reto_empresa(uuid) from public, anon;
revoke all on function public.candidatos_reto(uuid) from public, anon;
revoke all on function public.participantes_reto(uuid) from public, anon;
grant execute on function public.mis_retos_empresa() to authenticated;
grant execute on function public.detalle_reto_empresa(uuid) to authenticated;
grant execute on function public.candidatos_reto(uuid) to authenticated;
grant execute on function public.participantes_reto(uuid) to authenticated;

-- =====================================================================
-- 4.6 Empresa: seleccionar, descartar y aprobar con calificación
-- =====================================================================
create or replace function public.seleccionar_candidato(p_postulacion_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_reto uuid;
  v_est uuid;
  v_estado text;
  v_estado_reto text;
  v_dur smallint;
  v_cupos smallint;
  v_ocupados integer;
  v_acc uuid;
begin
  if (select auth.uid()) is null then raise exception 'NO_AUTENTICADO'; end if;

  select p.reto_id, p.estudiante_id, p.estado
    into v_reto, v_est, v_estado
  from public.reto_postulaciones p where p.id = p_postulacion_id;

  if not found then raise exception 'POSTULACION_NO_ENCONTRADA'; end if;
  if not public.es_dueno_reto(v_reto) then raise exception 'SIN_PERMISO'; end if;
  if v_estado <> 'pendiente' then raise exception 'ESTADO_INVALIDO'; end if;

  select r.duracion_dias, r.cupos, r.estado into v_dur, v_cupos, v_estado_reto
  from public.retos r where r.id = v_reto;
  if v_estado_reto <> 'publicado' then raise exception 'RETO_NO_DISPONIBLE'; end if;

  select count(*) into v_ocupados
  from public.reto_aceptaciones x
  where x.reto_id = v_reto and x.estado <> 'cancelado';
  if v_ocupados >= v_cupos then raise exception 'CUPOS_COMPLETOS'; end if;

  insert into public.reto_aceptaciones (reto_id, estudiante_id, vence_en)
  values (v_reto, v_est, current_date + v_dur)
  returning id into v_acc;

  update public.reto_postulaciones
  set estado = 'seleccionada', decidido_en = now()
  where id = p_postulacion_id;

  return v_acc;
exception
  when unique_violation then
    raise exception 'ESTADO_INVALIDO';
end;
$$;

create or replace function public.descartar_candidato(p_postulacion_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_reto uuid;
begin
  if (select auth.uid()) is null then raise exception 'NO_AUTENTICADO'; end if;

  select p.reto_id into v_reto
  from public.reto_postulaciones p where p.id = p_postulacion_id;
  if not found then raise exception 'POSTULACION_NO_ENCONTRADA'; end if;
  if not public.es_dueno_reto(v_reto) then raise exception 'SIN_PERMISO'; end if;

  update public.reto_postulaciones
  set estado = 'descartada', decidido_en = now()
  where id = p_postulacion_id and estado = 'pendiente';
  if not found then raise exception 'ESTADO_INVALIDO'; end if;
end;
$$;

drop function if exists public.aprobar_entrega(uuid);

create or replace function public.aprobar_entrega(
  p_aceptacion_id uuid,
  p_calificacion integer,
  p_comentario text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_estado text;
  v_reto uuid;
begin
  if (select auth.uid()) is null then raise exception 'NO_AUTENTICADO'; end if;
  if p_calificacion is null or p_calificacion not between 1 and 5 then
    raise exception 'CALIFICACION_INVALIDA';
  end if;

  select x.estado, x.reto_id into v_estado, v_reto
  from public.reto_aceptaciones x where x.id = p_aceptacion_id;

  if not found then raise exception 'ACEPTACION_NO_ENCONTRADA'; end if;
  if not public.es_dueno_reto(v_reto) then raise exception 'SIN_PERMISO'; end if;
  if v_estado <> 'entregado' then raise exception 'ESTADO_INVALIDO'; end if;

  update public.reto_aceptaciones
  set estado = 'completado',
      completado_en = now(),
      calificacion = p_calificacion,
      comentario_evaluacion = nullif(trim(p_comentario), '')
  where id = p_aceptacion_id;
end;
$$;

create or replace function public.devolver_entrega(
  p_aceptacion_id uuid,
  p_comentario text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_estado text;
  v_reto uuid;
begin
  if (select auth.uid()) is null then raise exception 'NO_AUTENTICADO'; end if;
  if length(trim(coalesce(p_comentario, ''))) < 3 then
    raise exception 'COMENTARIO_REQUERIDO';
  end if;

  select x.estado, x.reto_id into v_estado, v_reto
  from public.reto_aceptaciones x where x.id = p_aceptacion_id;

  if not found then raise exception 'ACEPTACION_NO_ENCONTRADA'; end if;
  if not public.es_dueno_reto(v_reto) then raise exception 'SIN_PERMISO'; end if;
  if v_estado <> 'entregado' then raise exception 'ESTADO_INVALIDO'; end if;

  update public.reto_aceptaciones
  set estado = 'aceptado', enviado_en = null,
      comentario_revision = trim(p_comentario)
  where id = p_aceptacion_id;
end;
$$;

revoke all on function public.seleccionar_candidato(uuid) from public, anon;
revoke all on function public.descartar_candidato(uuid) from public, anon;
revoke all on function public.aprobar_entrega(uuid, integer, text) from public, anon;
revoke all on function public.devolver_entrega(uuid, text) from public, anon;
grant execute on function public.seleccionar_candidato(uuid) to authenticated;
grant execute on function public.descartar_candidato(uuid) to authenticated;
grant execute on function public.aprobar_entrega(uuid, integer, text) to authenticated;
grant execute on function public.devolver_entrega(uuid, text) to authenticated;

-- =====================================================================
-- 4.7 Empresa: perfil
-- =====================================================================
create or replace function public.actualizar_perfil_empresa(
  p_nombre text,
  p_tipo text,
  p_telefono text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_nombre text := trim(coalesce(p_nombre, ''));
  v_tel text := nullif(trim(coalesce(p_telefono, '')), '');
begin
  if v_uid is null then raise exception 'NO_AUTENTICADO'; end if;
  if not exists (select 1 from public.perfiles p
                 where p.id = v_uid and p.rol in ('empresa', 'admin')) then
    raise exception 'SIN_PERMISO';
  end if;
  if length(v_nombre) < 2 or length(v_nombre) > 80 then
    raise exception 'NOMBRE_INVALIDO';
  end if;

  update public.perfiles
  set nombre = v_nombre,
      empresa_tipo = nullif(trim(coalesce(p_tipo, '')), ''),
      telefono = v_tel
  where id = v_uid;

  update public.retos set empresa_nombre = v_nombre where empresa_id = v_uid;
  update public.reto_contactos c
  set telefono = v_tel
  from public.retos r
  where r.id = c.reto_id and r.empresa_id = v_uid;
end;
$$;

revoke all on function public.actualizar_perfil_empresa(text, text, text) from public, anon;
grant execute on function public.actualizar_perfil_empresa(text, text, text) to authenticated;

-- =====================================================================
-- 4.8 Estudiante: postularse, retirarse, mis postulaciones
-- =====================================================================
drop function if exists public.aceptar_reto(uuid);

create or replace function public.postularse(p_reto_id uuid, p_respuestas jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_rol text;
  v_cupos smallint;
  v_ocupados integer;
  v_q record;
  v_resp text;
  v_id uuid;
begin
  if v_uid is null then raise exception 'NO_AUTENTICADO'; end if;

  select p.rol into v_rol from public.perfiles p where p.id = v_uid;
  if v_rol = 'empresa' then raise exception 'SOLO_ESTUDIANTES'; end if;

  select r.cupos into v_cupos
  from public.retos r
  where r.id = p_reto_id and r.estado = 'publicado' and r.fecha_limite >= current_date;
  if not found then raise exception 'RETO_NO_DISPONIBLE'; end if;

  select count(*) into v_ocupados
  from public.reto_aceptaciones x
  where x.reto_id = p_reto_id and x.estado <> 'cancelado';
  if v_ocupados >= v_cupos then raise exception 'CUPOS_COMPLETOS'; end if;

  for v_q in
    select q.orden, q.tipo, q.opciones from public.reto_preguntas q
    where q.reto_id = p_reto_id order by q.orden
  loop
    select trim(coalesce(t.e->>'respuesta', '')) into v_resp
    from jsonb_array_elements(coalesce(p_respuestas, '[]'::jsonb)) as t(e)
    where (t.e->>'orden')::integer = v_q.orden
    limit 1;

    if coalesce(v_resp, '') = '' then raise exception 'RESPUESTA_FALTANTE'; end if;
    if v_q.tipo = 'opcion' and not (v_resp = any (v_q.opciones)) then
      raise exception 'RESPUESTA_INVALIDA';
    end if;
    if v_q.tipo = 'texto' and (length(v_resp) < 3 or length(v_resp) > 300) then
      raise exception 'RESPUESTA_INVALIDA';
    end if;
  end loop;

  insert into public.reto_postulaciones (reto_id, estudiante_id, respuestas)
  select p_reto_id, v_uid,
         coalesce(jsonb_agg(jsonb_build_object(
           'orden', q.orden,
           'pregunta', q.enunciado,
           'respuesta', trim(a.e->>'respuesta'))
           order by q.orden), '[]'::jsonb)
  from public.reto_preguntas q
  join lateral (
    select t.e
    from jsonb_array_elements(coalesce(p_respuestas, '[]'::jsonb)) as t(e)
    where (t.e->>'orden')::integer = q.orden
    limit 1
  ) a on true
  where q.reto_id = p_reto_id
  on conflict (reto_id, estudiante_id) do update
    set estado = 'pendiente', respuestas = excluded.respuestas,
        creado_en = now(), decidido_en = null
    where public.reto_postulaciones.estado = 'retirada'
  returning id into v_id;

  if v_id is null then raise exception 'YA_POSTULADO'; end if;
  return v_id;
end;
$$;

create or replace function public.retirar_postulacion(p_reto_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null then raise exception 'NO_AUTENTICADO'; end if;

  update public.reto_postulaciones
  set estado = 'retirada', decidido_en = now()
  where reto_id = p_reto_id
    and estudiante_id = (select auth.uid())
    and estado = 'pendiente';
  if not found then raise exception 'ESTADO_INVALIDO'; end if;
end;
$$;

create or replace function public.mis_postulaciones()
returns table (
  reto_id uuid, titulo text, empresa_nombre text, area_nombre text,
  presupuesto_usd integer, estado text, creado_en timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select r.id, r.titulo, r.empresa_nombre, a.nombre, r.presupuesto_usd,
         p.estado, p.creado_en
  from public.reto_postulaciones p
  join public.retos r on r.id = p.reto_id
  join public.areas a on a.id = r.area_id
  where p.estudiante_id = (select auth.uid())
    and p.estado in ('pendiente', 'descartada')
  order by p.creado_en desc;
$$;

revoke all on function public.postularse(uuid, jsonb) from public, anon;
revoke all on function public.retirar_postulacion(uuid) from public, anon;
revoke all on function public.mis_postulaciones() from public, anon;
grant execute on function public.postularse(uuid, jsonb) to authenticated;
grant execute on function public.retirar_postulacion(uuid) to authenticated;
grant execute on function public.mis_postulaciones() to authenticated;

-- =====================================================================
-- 4.9 Estudiante: detalle del reto y mis retos (versiones nuevas)
-- =====================================================================
drop function if exists public.obtener_reto(uuid);

create or replace function public.obtener_reto(p_reto_id uuid)
returns table (
  id uuid, titulo text, descripcion text, entregables text[],
  empresa_nombre text, area_slug text, area_nombre text, habilidades text[],
  duracion_dias smallint, presupuesto_usd integer, fecha_limite date,
  estado text, cupos smallint, cupos_ocupados bigint, preguntas jsonb,
  contacto_correo text, contacto_telefono text, ya_aceptado boolean,
  postulacion_estado text
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    r.id, r.titulo, r.descripcion, r.entregables, r.empresa_nombre,
    a.slug, a.nombre,
    coalesce(array(
      select h.nombre from public.reto_habilidades rh
      join public.habilidades h on h.id = rh.habilidad_id
      where rh.reto_id = r.id order by h.nombre), '{}'::text[]),
    r.duracion_dias, r.presupuesto_usd, r.fecha_limite, r.estado, r.cupos,
    (select count(*) from public.reto_aceptaciones x
      where x.reto_id = r.id and x.estado <> 'cancelado'),
    coalesce((
      select jsonb_agg(jsonb_build_object(
               'orden', q.orden, 'tipo', q.tipo,
               'enunciado', q.enunciado, 'opciones', to_jsonb(q.opciones))
             order by q.orden)
      from public.reto_preguntas q where q.reto_id = r.id), '[]'::jsonb),
    case when (select auth.uid()) is not null then c.correo end,
    case when (select auth.uid()) is not null then c.telefono end,
    exists (select 1 from public.reto_aceptaciones x
            where x.reto_id = r.id and x.estudiante_id = (select auth.uid())),
    (select p.estado from public.reto_postulaciones p
      where p.reto_id = r.id and p.estudiante_id = (select auth.uid()))
  from public.retos r
  join public.areas a on a.id = r.area_id
  left join public.reto_contactos c on c.reto_id = r.id
  where r.id = p_reto_id
    and (
      (r.estado = 'publicado' and r.fecha_limite >= current_date)
      or public.es_admin()
      or r.empresa_id = (select auth.uid())
      or exists (select 1 from public.reto_aceptaciones x
                 where x.reto_id = r.id and x.estudiante_id = (select auth.uid()))
    );
$$;

revoke all on function public.obtener_reto(uuid) from public;
grant execute on function public.obtener_reto(uuid) to anon, authenticated;

drop function if exists public.mis_retos();

create or replace function public.mis_retos()
returns table (
  aceptacion_id uuid, reto_id uuid, titulo text, empresa_nombre text,
  area_nombre text, presupuesto_usd integer, vence_en date, estado text,
  entregables text[], items_marcados smallint[], entrega_enlace text,
  entrega_nota text, comentario_revision text, aceptado_en timestamptz,
  enviado_en timestamptz, completado_en timestamptz, calificacion smallint,
  comentario_evaluacion text, contacto_correo text, contacto_telefono text
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    x.id, r.id, r.titulo, r.empresa_nombre, a.nombre, r.presupuesto_usd,
    x.vence_en, x.estado, r.entregables, x.items_marcados, x.entrega_enlace,
    x.entrega_nota, x.comentario_revision, x.aceptado_en, x.enviado_en,
    x.completado_en, x.calificacion, x.comentario_evaluacion,
    c.correo, c.telefono
  from public.reto_aceptaciones x
  join public.retos r on r.id = x.reto_id
  join public.areas a on a.id = r.area_id
  left join public.reto_contactos c on c.reto_id = r.id
  where x.estudiante_id = (select auth.uid())
    and x.estado <> 'cancelado'
  order by
    case x.estado when 'aceptado' then 0 when 'entregado' then 1 else 2 end,
    x.vence_en;
$$;

revoke all on function public.mis_retos() from public, anon;
grant execute on function public.mis_retos() to authenticated;

-- =====================================================================
-- 4.10 Datos falsos para comprobar
-- =====================================================================
insert into public.reto_preguntas (reto_id, orden, tipo, enunciado, opciones)
select r.id, v.orden, v.tipo, v.enunciado, v.opciones
from public.retos r
cross join (values
  (1, 'opcion', '¿Cuánta experiencia tienes con las herramientas de este reto?',
     array['Ninguna, quiero aprender', 'Básica', 'Intermedia', 'Avanzada']::text[]),
  (2, 'opcion', '¿Cuántas horas por día puedes dedicarle?',
     array['Menos de 1 hora', '1 a 2 horas', '3 a 4 horas', 'Más de 4 horas']::text[]),
  (3, 'texto', 'En pocas palabras, ¿cómo abordarías este reto?', null::text[])
) as v(orden, tipo, enunciado, opciones)
where r.estado = 'publicado'
on conflict (reto_id, orden) do nothing;

insert into public.reto_postulaciones (reto_id, estudiante_id, respuestas)
select r.id,
       (select p.id from public.perfiles p
        where p.correo = 'admin.prueba@correo.unimet.edu.ve'),
       '[{"orden":1,"pregunta":"¿Cuánta experiencia tienes con las herramientas de este reto?","respuesta":"Intermedia"},
         {"orden":2,"pregunta":"¿Cuántas horas por día puedes dedicarle?","respuesta":"3 a 4 horas"},
         {"orden":3,"pregunta":"En pocas palabras, ¿cómo abordarías este reto?","respuesta":"Empezaría limpiando el Excel y luego armaría los tres indicadores con filtros por mes."}]'::jsonb
from public.retos r
where r.titulo = 'Dashboard de ventas en Power BI'
on conflict (reto_id, estudiante_id) do nothing;

select 'OK' as resultado;
