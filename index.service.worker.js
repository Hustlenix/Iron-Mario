self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', event => event.waitUntil((async () => {
  await self.clients.claim();
  await self.registration.unregister();
  const windows = await self.clients.matchAll({type: 'window'});
  for (const client of windows) {
    if (client.url.startsWith(self.registration.scope)) await client.navigate(client.url);
  }
})()));
