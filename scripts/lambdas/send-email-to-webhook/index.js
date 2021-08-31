// Using js file since lambda function doesn't support typescript by default
// to use ts in lambda you have to set up custom runtime (April 5, 2020)
const request = require("requestretry");

const parseEmailAddress = (email) => {
  const found = email.match("<(.*?)>");

  if (!found[1]) {
    throw new Error(`Invalid email address: ${email}`);
  }

  return found[1];
};

const handler = async (event) => {
  const url = process.env.WEBHOOK_URL;

  if (!url) {
    throw new Error("Missing WEBHOOK_URL environment variable!");
  }

  const mail = event.Records[0].ses.mail;
  const messageId = mail.messageId;
  const toAddresses = mail.commonHeaders.to;
  const fromAddress = mail.commonHeaders.from;

  if (!messageId || !toAddresses || !fromAddress) {
    throw new Error("Missing required fields in message (messageId/to/from)");
  }

  const headers = mail.headers.reduce((acc, header) => {
    const { name, value } = header;

    if (name && value) {
      return { ...acc, [name.toLowerCase()]: value };
    } else {
      return acc;
    }
  }, {});

  const parsedToAddresses = toAddresses.map((addr) => parseEmailAddress(addr));
  const parsedFromAddresses = fromAddress.map((addr) =>
    parseEmailAddress(addr)
  );

  const params = {
    url: `${url}/api/ses/webhook`,
    body: {
      // Raw mail object
      mail,
      // Relevant fields
      message_id: messageId,
      to_addresses: parsedToAddresses,
      from_address: parsedFromAddresses,
      forwarded_to: headers["x-forwarded-to"],
      // Deprecated fields
      messageId,
      toAddresses: parsedToAddresses,
      fromAddress: parsedFromAddresses,
    },
    json: true,
  };

  return await request.post(params);
};

exports.handler = handler;
