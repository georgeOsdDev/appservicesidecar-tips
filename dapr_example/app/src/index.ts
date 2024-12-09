import { serve } from '@hono/node-server'
import { Hono } from 'hono'
import { serveStatic } from '@hono/node-server/serve-static'
import { poweredBy } from 'hono/powered-by'
import { logger } from 'hono/logger'
import process = require('process')

import { CommunicationProtocolEnum, DaprClient } from "@dapr/dapr";

// JS SDK does not support Configuration API over HTTP protocol yet
const communicationProtocol = CommunicationProtocolEnum.GRPC;
const daprHost = process.env.DAPR_HOST ?? "localhost"
const daprHttpPort = process.env.DAPR_HTTP_PORT ?? '3500'
const daprGrpcPort = process.env.DAPR_GRPC_PORT ?? '50001'
let client: DaprClient;

const app = new Hono()
app.use('/static/*', serveStatic({ root: './' }))
app.use('*', poweredBy())
app.use('*', logger())

app.notFound((c) => c.json({ message: 'Not Found', ok: false }, 404))
app.get('/', (c) => {
  console.log('Hello Hono!')
  return c.text('Hello Hono!')
})


let batchLastCalledTime: string = "00:00:00";
app.post('/.internal/batch', async (c) => {
  batchLastCalledTime = new Date().toLocaleTimeString();

  if (!client) {
    client = new DaprClient({daprHost, daprPort: daprGrpcPort, communicationProtocol});
  }
  const bindingName = "blob";
  const bindingOperation = "create";
  const data = batchLastCalledTime;
  const metadata = {
    "blobName": `batch_${Date.now()}.txt`,
  };
  await client.binding.send(bindingName, bindingOperation, data, metadata);

  return c.text('Hello Internal batch');
});

app.get('/batchstatus', (c) => {
  return c.text('batchLastCalledTime:' + batchLastCalledTime);
});

app.get('/.internal/healthz', (c) => {
  return c.text('Hello Internal health check')
})

// use DaprClient to call Dapr API via gRPC
app.post('/blob/create', async (c) => {
  if (!client) {
    client = new DaprClient({daprHost, daprPort: daprGrpcPort, communicationProtocol})
  }
  // get request body
  const req = await c.req.json()
  const bindingName = "blob";
  const bindingOperation = "create";
  const data = { message: "hello" };
  const metadata = {
    "blobName": req.blobName ?? `example_${Date.now()}.txt`,
  };
  const result = await client.binding.send(bindingName, bindingOperation, data, metadata);

  return c.json(result)
})

// use DaprClient to call Dapr API via Http
app.post('/blob/create2', async (c) => {
  const url = `http://${daprHost}:${daprHttpPort}/v1.0/bindings/blob`;
  const payload = {
    data: { message: "hello api" },
    metadata: {
      blobName: `example_${Date.now()}.txt`
    },
    operation: 'create'
  };

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(payload)
  });
  // get request body
  if (response.ok) {
    console.log('Data saved successfully');
    return c.text('Data saved successfully');
  } else {
    console.error('Failed to save data', await response.text());
    return c.text('Error saving data');
  }
})

const port = process.env.PORT ? Number(process.env.PORT) : 9000
console.log(`Server is running on http://localhost:${port}`)

serve({
  fetch: app.fetch,
  port,
})
