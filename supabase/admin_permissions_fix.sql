-- Run in Supabase SQL Editor as project owner. Does not delete data.
-- Keeps customer payment status controlled by existing payment/backend logic.
CREATE OR REPLACE FUNCTION public.is_nexrig_admin()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = '' AS $$
  SELECT EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = (SELECT auth.uid()));
$$;
REVOKE ALL ON FUNCTION public.is_nexrig_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_nexrig_admin() TO authenticated;

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Nexrig admins manage products" ON public.products;
CREATE POLICY "Nexrig admins manage products" ON public.products
  FOR ALL TO authenticated
  USING ((SELECT public.is_nexrig_admin()))
  WITH CHECK ((SELECT public.is_nexrig_admin()));

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
-- Read all orders for admin; customer own-orders policies remain intact.
DROP POLICY IF EXISTS "Nexrig admins read orders" ON public.orders;
CREATE POLICY "Nexrig admins read orders" ON public.orders
  FOR SELECT TO authenticated USING ((SELECT public.is_nexrig_admin()));
-- Only allow admin to change shipping_status via restricted RPC, not arbitrary payment fields.
DROP POLICY IF EXISTS "Nexrig admins manage orders" ON public.orders;

CREATE OR REPLACE FUNCTION public.admin_update_shipping_status(p_order_id uuid, p_status text)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  IF NOT (SELECT public.is_nexrig_admin()) THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;
  IF p_status NOT IN ('pending','processing','shipped','delivered','cancelled') THEN
    RAISE EXCEPTION 'Invalid shipping status';
  END IF;
  UPDATE public.orders SET shipping_status = p_status WHERE id = p_order_id;
  RETURN FOUND;
END;
$$;
REVOKE ALL ON FUNCTION public.admin_update_shipping_status(uuid,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_update_shipping_status(uuid,text) TO authenticated;

ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Nexrig admins read order items" ON public.order_items;
CREATE POLICY "Nexrig admins read order items" ON public.order_items
  FOR SELECT TO authenticated USING ((SELECT public.is_nexrig_admin()));
-- IMPORTANT: Audit all other permissive policies before production deployment.
