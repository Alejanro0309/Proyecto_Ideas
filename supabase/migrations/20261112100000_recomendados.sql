-- =====================================================================
-- Función de retos recomendados para el panel.
-- Excluye los retos que el usuario actual YA aceptó (en cualquier estado,
-- salvo cancelados), para no recomendarle lo que ya tiene en curso o
-- completado.
-- =====================================================================
create or replace function public.recomendados(p_limit integer default 6)
returns table (
  id uuid,
  titulo text,
  empresa_nombre text,
  area_slug text,
  area_nombre text,
  habilidades text[],
  duracion_dias smallint,
  presupuesto_usd integer,
  fecha_limite date,
  creado_en timestamptz
)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    r.id,
    r.titulo,
    r.empresa_nombre,
    a.slug,
    a.nombre,
    coalesce(
      array(
        select h.nombre
        from public.reto_habilidades rh
        join public.habilidades h on h.id = rh.habilidad_id
        where rh.reto_id = r.id
        order by h.nombre
      ),
      '{}'::text[]
    ),
    r.duracion_dias,
    r.presupuesto_usd,
    r.fecha_limite,
    r.creado_en
  from public.retos r
  join public.areas a on a.id = r.area_id
  where r.estado = 'publicado'
    and r.fecha_limite >= current_date
    -- No recomendar lo que el usuario ya aceptó.
    and not exists (
      select 1
      from public.reto_aceptaciones x
      where x.reto_id = r.id
        and x.estudiante_id = (select auth.uid())
        and x.estado <> 'cancelado'
    )
  order by r.creado_en desc
  limit least(greatest(p_limit, 1), 20);
$$;

revoke all on function public.recomendados(integer) from public, anon;
grant execute on function public.recomendados(integer) to authenticated;

select 'OK' as resultado;
