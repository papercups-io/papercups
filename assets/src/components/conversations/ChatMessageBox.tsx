import React from 'react';
import ReactMarkdown from 'react-markdown';
import breaks from 'remark-breaks';
import {Box} from 'theme-ui';
import {allowedNodeTypes} from '../common';

type ChatMessageBoxProps = {
  className?: string;
  content: string;
  sx?: object;
};

const ChatMessageBox = ({className, content, sx}: ChatMessageBoxProps) => {
  const parsedSx = Object.assign(sx, {
    borderRadius: 4,
    p: {
      mb: 0,
    },
    blockquote: {
      px: 2,
      borderLeft: '3px solid',
      mb: 0,
    },
  });

  return (
    <Box sx={parsedSx}>
      <ReactMarkdown
        className={`Text--markdown ${className}`}
        source={content}
        allowedTypes={allowedNodeTypes}
        plugins={[breaks]}
      />
    </Box>
  );
};

export default ChatMessageBox;
