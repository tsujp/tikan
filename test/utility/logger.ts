// prevents TS errors
declare var self: Worker;

self.onmessage = (event: MessageEvent) => {
  console.log('logger received:', event.data);
  postMessage("world");
};