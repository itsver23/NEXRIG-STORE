-- Run in Supabase SQL Editor as project owner.
CREATE TABLE IF NOT EXISTS public.admin_users (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins can read their own membership" ON public.admin_users;
CREATE POLICY "Admins can read their own membership" ON public.admin_users
  FOR SELECT TO authenticated USING (user_id = (SELECT auth.uid()));
-- Admin membership is assigned ONLY from SQL Editor / trusted server, never client registration.
CREATE OR REPLACE FUNCTION public.is_nexrig_admin()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = '' AS $$
  SELECT EXISTS(SELECT 1 FROM public.admin_users WHERE user_id = (SELECT auth.uid()));
$$;
REVOKE ALL ON FUNCTION public.is_nexrig_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_nexrig_admin() TO authenticated;

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Nexrig admins manage products" ON public.products;
CREATE POLICY "Nexrig admins manage products" ON public.products
  FOR ALL TO authenticated USING ((SELECT public.is_nexrig_admin()))
  WITH CHECK ((SELECT public.is_nexrig_admin()));
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Nexrig admins manage orders" ON public.orders;
CREATE POLICY "Nexrig admins manage orders" ON public.orders
  FOR ALL TO authenticated USING ((SELECT public.is_nexrig_admin()))
  WITH CHECK ((SELECT public.is_nexrig_admin()));

-- After registering your intended admin account, run separately:
-- INSERT INTO public.admin_users (user_id)
-- SELECT id FROM auth.users WHERE email = 'your-admin-email@example.com'
-- ON CONFLICT (user_id) DO NOTHING;
-- NOTE: Existing permissive policies remain in effect; audit them before production.
