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
