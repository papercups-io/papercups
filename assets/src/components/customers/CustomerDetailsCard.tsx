import React from 'react';
import {Box} from 'theme-ui';
import {SxStyleProp} from 'theme-ui';

import {colors} from '../common';

const CustomerDetailsCard = ({
  children,
  sx = {},
}: {
  children: any;
  sx?: SxStyleProp;
}) => {
  return (
    <Box
      sx={{
        bg: colors.white,
        border: '1px solid rgba(0,0,0,.06)',
        borderRadius: 4,
        ...sx,
      }}
    >
      {children}
    </Box>
  );
};

export default CustomerDetailsCard;
