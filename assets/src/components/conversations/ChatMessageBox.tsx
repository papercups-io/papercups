import React from 'react';
import ReactMarkdown from 'react-markdown';
import {Box} from 'theme-ui';
import {colors, allowedNodeTypes} from '../common';

type ChatMessageBoxProps = {
  content: string;
  px: number;
  py: number;
  sx: object;
};

const ChatMessageBox = ({content, px, py, sx}: ChatMessageBoxProps) => {
  const parsedSx = Object.assign(sx, {
    borderRadius: 4,
    h1: {
      color: colors.white,
    },
    h2: {
      color: colors.white,
    },
    h3: {
      color: colors.white,
    },
    h4: {
      color: colors.white,
    },
    h5: {
      color: colors.white,
    },
    h6: {
      color: colors.white,
    },
    a: {
      color: colors.white,
      cursor: 'pointer',
    },
    'a:hover': {
      textDecoration: 'underline',
    },
    p: {
      mb: 0,
    },
    blockquote: {
      px: 2,
      borderLeft: '3px solid',
      borderColor: colors.white,
      mb: 0,
    },
  });

  return (
    <Box px={px} py={py} sx={parsedSx}>
      <ReactMarkdown source={content} allowedTypes={allowedNodeTypes} />
    </Box>
  );
};

export default ChatMessageBox;
