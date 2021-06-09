const PREFIX = '__PAPERCUPS__';

const get = (key: string) => {
  const result = localStorage.getItem(`${PREFIX}${key}`);

  if (!result) {
    return null;
  }

  try {
    return JSON.parse(result);
  } catch (e) {
    return result;
  }
};

const set = (key: string, value: any) => {
  localStorage.setItem(`${PREFIX}${key}`, JSON.stringify(value));
};

const remove = (key: string) => {
  localStorage.removeItem(`${PREFIX}${key}`);
};

// TODO: improve these names

export const getAuthTokens = () => get('__AUTH_TOKENS__');

export const setAuthTokens = (tokens: any) => set('__AUTH_TOKENS__', tokens);

export const removeAuthTokens = () => remove('__AUTH_TOKENS__');

export const getCustomerId = () => get('__CUSTOMER_ID__');

export const setCustomerId = (id: string) => set('__CUSTOMER_ID__', id);

export const removeCustomerId = () => remove('__CUSTOMER_ID__');

export const getBotDemoFaqs = () => get(':__BOT_DEMO_FAQS__');

export const setBotDemoFaqs = (faqs: any) => set(':__BOT_DEMO_FAQS__', faqs);

export const removeBotDemoFaqs = () => remove(':__BOT_DEMO_FAQS__');

export const getRunKitCode = (prefix: string) =>
  get(`:__RUNKIT_SOURCE_CODE__:${prefix}`);

export const setRunKitCode = (prefix: string, code: any) =>
  set(`:__RUNKIT_SOURCE_CODE__:${prefix}`, code);

export const removeRunKitCode = (prefix: string) =>
  remove(`:__RUNKIT_SOURCE_CODE__:${prefix}`);
