// Using js file since lambda function doesn't support typescript by default
// to use ts in lambda you have to set up custom runtime (April 5, 2020)
const request = require("requestretry");

const parseFromAddress = (email) => {
  const found = email.match("<(.*?)>");

  if (!found[1]) {
    throw Error(`Invalid email address: ${email}`);
  }

  return found[1];
};

const handler = async (event) => {
  const url = process.env.WEBHOOK_URL;

  if (!url) {
    throw Error("MISSING WEBHOOK URL ENVIRONMENT VARIABLE");
  }

  const mail = event.Records[0].ses.mail;
  const messageId = mail.messageId;
  const toAddresses = mail.commonHeaders.to;
  const fromAddress = mail.commonHeaders.from;

  if (!messageId || !toAddresses || !fromAddress) {
    throw Error("Missing required fields in message");
  }

  const params = {
    url: `${url}/api/ses/webhook`,
    body: {
      messageId,
      toAddresses,
      fromAddress: fromAddress.map((addr) => parseFromAddress(addr)),
    },
    json: true,
  };

  return await request.post(params);
};

exports.handler = handler;
