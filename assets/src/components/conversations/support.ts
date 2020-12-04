import {colors} from '../common';

const {primary, gold, red, green, purple, magenta} = colors;

export const getColorByUuid = (uuid?: string | null) => {
  if (!uuid) {
    return primary;
  }

  const colorIndex = parseInt(uuid, 32) % 5;
  const color = [gold, red, green, purple, magenta][colorIndex];

  return color;
};
