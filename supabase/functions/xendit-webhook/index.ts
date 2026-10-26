import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
serve(async (req) => {
  if (req.method !== 'POST') return new Response('Method not allowed', { status: 405 });
  const expected = Deno.env.get('XENDIT_WEBHOOK_TOKEN');
  if (!expected || req.headers.get('x-callback-token') !== expected) return new Response('Unauthorized', { status: 401 });
  try {
    const event = await req.json();
    if (typeof event.external_id !== 'string' || !event.external_id.startsWith('nexrig_') || !['PAID','EXPIRED','FAILED'].includes(event.status) || !Number.isFinite(Number(event.amount))) return new Response('Invalid event', { status: 400 });
    const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
    const { data: order, error } = await admin.from('orders').select('id,amount,status').eq('external_id', event.external_id).maybeSingle();
    if (error) throw error;
    if (!order) return new Response('Order not found', { status: 404 });
    if (Number(order.amount) !== Number(event.amount)) return new Response('Amount mismatch', { status: 400 });
    if (order.status !== 'PENDING') return Response.json({ received: true, status: order.status });
    const next = event.status === 'PAID' ? 'PAID' : 'FAILED';
    const { error: updateError } = await admin.from('orders').update({ status: next }).eq('id', order.id).eq('status', 'PENDING');
    if (updateError) throw updateError;
    return Response.json({ received: true });
  } catch (e) {
    console.error('Webhook error', e);
    return new Response('Webhook error', { status: 500 });
  }
});
