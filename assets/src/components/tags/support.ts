import {colors} from '../common';

export const TAG_COLORS = [
  {name: 'default', hex: '#fafafa'},
  {name: 'magenta', hex: colors.magenta},
  {name: 'red', hex: colors.red},
  {name: 'volcano', hex: colors.volcano},
  {name: 'purple', hex: colors.purple},
  {name: 'blue', hex: colors.blue},
];

export const defaultTagColor = (index: number) => {
  const options = TAG_COLORS.slice(1).map((color) => color.name);

  return options[index % options.length];
};

export const formatTagErrors = (err: any) => {
  try {
    const error = err?.response?.body?.error ?? {};
    const {errors = {}, message, status} = error;

    if (status === 422 && Object.keys(errors).length > 0) {
      const messages = Object.keys(errors)
        .map((field) => {
          const description = errors[field];

          if (description) {
            return `${field} ${description}`;
          } else {
            return `invalid ${field}`;
          }
        })
        .join(', ');

      return `Error: ${messages}.`;
    } else {
      return (
        message ||
        err?.message ||
        'Something went wrong. Please contact us or try again in a few minutes.'
      );
    }
  } catch {
    return (
      err?.response?.body?.error?.message ||
      err?.message ||
      'Something went wrong. Please contact us or try again in a few minutes.'
    );
  }
};
