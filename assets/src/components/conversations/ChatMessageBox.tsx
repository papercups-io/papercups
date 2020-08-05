import React from 'react';
import DOMPurify from 'dompurify';
import marked from 'marked';
import {Box, Flex} from 'theme-ui';
import {colors} from '../common';

type ChatMessageBoxProps = {
  content: string;
  px: number;
  py: number;
  sx: object;
};

const ChatMessageBox = ({content, px, py, sx}: ChatMessageBoxProps) => {
  const markupContent = DOMPurify.sanitize(marked(content));
  const parsedSx = Object.assign(sx, {
    borderRadius: 4,
    a: {
      color: colors.white,
      cursor: 'pointer',
    },
    'a:hover': {
      textDecoration: 'underline',
    },
    p: {
      display: 'inherit',
    },
  });

  return (
    <Box px={px} py={py} sx={parsedSx}>
      <span dangerouslySetInnerHTML={{__html: markupContent}} />
    </Box>
  );
};

export default ChatMessageBox;
