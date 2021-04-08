import React from 'react';
import ReactMarkdown from 'react-markdown';
import breaks from 'remark-breaks';
import {Twemoji} from 'react-emoji-render';
import {Box} from 'theme-ui';
import {allowedNodeTypes} from '../common';
import {Attachment} from '../../types';
import {PaperClipOutlined} from '../icons';

const renderers = {
  text: (props: any) => {
    return <Twemoji text={props.children} />;
  },
  image: (props: any) => {
    return <img {...props} style={{maxWidth: '100%', maxHeight: 400}} />;
  },
};

const ChatMessageAttachment = ({
  attachment,
  color,
}: {
  attachment: Attachment;
  color?: string;
}) => {
  const {id, filename, file_url: fileUrl} = attachment;

  return (
    <Box key={id}>
      <PaperClipOutlined />{' '}
      <a
        href={fileUrl}
        style={{
          color,
          textDecoration: 'underline',
        }}
      >
        {filename}
      </a>
    </Box>
  );
};

type Props = {
  className?: string;
  content: string;
  sx?: Record<any, any>;
  attachments?: Attachment[];
  attachmentTextColor?: string;
};

const ChatMessageBox = ({
  className,
  content,
  sx,
  attachments = [],
  attachmentTextColor,
}: Props) => {
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

      {attachments && attachments.length > 0 && (
        <Box mt={2} className={className}>
          {attachments.map((attachment) => {
            return (
              <ChatMessageAttachment
                key={attachment.id}
                attachment={attachment}
                color={attachmentTextColor}
              />
            );
          })}
        </Box>
      )}
    </Box>
  );
};

export default ChatMessageBox;
