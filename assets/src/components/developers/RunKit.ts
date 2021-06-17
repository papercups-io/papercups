export const RunKit = (window as any).RunKit;

export const DEFAULT_LAMBDA_PREAMBLE = `
const noop = () => {};

exports.handler = typeof handler == 'function' ? handler : noop;
`;

export const DEFAULT_ENDPOINT_PREAMBLE = `
  const express = require("@runkit/runkit/express-endpoint/1.0.0");
  const bodyParser = require('body-parser');
  const cors = require('cors');

  const app = express(exports);

  app.use(cors());
  app.use(bodyParser.json());
  app.use(bodyParser.urlencoded({extended: true}));

  app.get('/', async (req, res) => {
    if (typeof run == 'function') {
      try {
        const params = {...req.body, ...req.params, ...req.query};
        const result = await run(params)

        return res.json({ok: true, data: result});
      } catch (error) {
        return res.json({ok: false, error, message: String(error)});
      }
    } else {
      return res.json({ok: true, data: null});
    }
  });

  app.post('/', async (req, res) => {
    console.debug('Webhook event:', req.body);
    const {event, payload} = req.body;
  
    switch (event) {
      case 'webhook:verify':
        return res.send(payload);
      default:
        if (typeof handler == 'function') {
          try {
            const result = await handler({event, payload})

            return res.json({ok: true, data: result});
          } catch (error) {
            return res.json({ok: false, error});
          }
        } else {
          return res.json({ok: true, data: payload});
        }
    }
  });
`;

export const DEFAULT_RUNKIT_SOURCE = `
const papercups = require('@papercups-io/papercups')(
  process.env.PAPERCUPS_API_KEY,
  {host: "${window.location.origin}"}
);

async function run(params = {}) {
  const customers = await papercups.customers.list({
    limit: 3
  });
  
  return customers;
}
`.trim();

export const WEBHOOK_HANDLER_SOURCE = `
const papercups = require('@papercups-io/papercups')(
  process.env.PAPERCUPS_API_KEY,
  {host: "${window.location.origin}"}
);

async function handler({event, payload}) {
  switch (event) {
    // See https://docs.papercups.io/webhook-events#messagecreated
    case 'message:created':
      return handleMessageCreated(payload);
    default:
      return {event, payload, me: await papercups.me()};
  }
}

async function handleMessageCreated(message) {
  const {body, customer_id, conversation_id} = message;
  const isCustomerMessage = !!customer_id;

  if (isCustomerMessage && body.toLowerCase().startsWith('test')) {
    // See https://docs.papercups.io/api-endpoints#messages
    return papercups.messages.create({
        body: 'Success!',
        type: 'bot',
        conversation_id,
    });
  }

  return message;
}
`.trim();

export default RunKit;
