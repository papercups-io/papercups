import React from 'react';
import ReactMarkdown from 'react-markdown';
import breaks from 'remark-breaks';
import {Twemoji} from 'react-emoji-render';
import {Box} from 'theme-ui';
import {allowedNodeTypes} from '../common';
import {Upload} from '../../types';
import {PaperClipOutlined} from '../icons';

const renderers = {
  text: (props: any) => {
    return <Twemoji text={props.children} />;
  },
};

type ChatMessageBoxProps = {
  className?: string;
  content: string;
  sx?: Record<any, any>;
  uploads?: Upload[];
  uploadColor?: string;
};

const ChatMessageBox = ({
  className,
  content,
  sx,
  uploads,
  uploadColor,
}: ChatMessageBoxProps) => {
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
        renderers={renderers}
        plugins={[breaks]}
      />
      {uploads &&
        uploads.length > 0 &&
        uploads.map((u) => {
          return (
            <div>
              <br></br>
              <PaperClipOutlined
                style={{color: uploadColor}}
              ></PaperClipOutlined>
              <a
                href={u.file_url}
                style={{color: uploadColor, textDecoration: 'underline'}}
              >
                {' '}
                {u.filename}
              </a>
            </div>
          );
        })}
    </Box>
  );
};

export default ChatMessageBox;
