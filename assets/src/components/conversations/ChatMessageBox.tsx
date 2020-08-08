import React from 'react';
import ReactMarkdown from 'react-markdown';
import {Box} from 'theme-ui';
import {allowedNodeTypes} from '../common';

type ChatMessageBoxProps = {
  content: string;
  textColor: string;
  px: number;
  py: number;
  sx: object;
};

const ChatMessageBox = ({
  content,
  textColor,
  px,
  py,
  sx,
}: ChatMessageBoxProps) => {
  const parsedSx = Object.assign(sx, {
    borderRadius: 4,
    color: textColor,
    h1: {
      color: textColor,
    },
    h2: {
      color: textColor,
    },
    h3: {
      color: textColor,
    },
    h4: {
      color: textColor,
    },
    h5: {
      color: textColor,
    },
    h6: {
      color: textColor,
    },
    a: {
      color: textColor,
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
      borderColor: textColor,
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
