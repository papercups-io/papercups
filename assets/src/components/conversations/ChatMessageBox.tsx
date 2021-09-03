import React from 'react';
import {Box, Flex} from 'theme-ui';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import sanitizeHtml from 'sanitize-html';

import {MarkdownRenderer, Text} from '../common';
import {Attachment, Message, MessageSource} from '../../types';
import {PaperClipOutlined} from '../icons';

dayjs.extend(utc);

const getMessageSourceDetails = (source?: MessageSource) => {
  switch (source) {
    case 'email':
      return ['email', '/gmail.svg'];
    case 'slack':
      return ['Slack', '/slack.svg'];
    case 'mattermost':
      return ['Mattermost', '/mattermost.svg'];
    case 'sms':
      return ['SMS', '/twilio.svg'];
    case 'api':
      return ['API', '/logo.svg'];
    case 'sandbox':
      return ['sandbox', '/logo.svg'];
    case 'chat':
    default:
      return [];
  }
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
  message: Message;
  sx?: Record<any, any>;
  attachments?: Attachment[];
  attachmentTextColor?: string;
};

const ChatMessageBox = ({
  className,
  message,
  sx,
  attachments = [],
  attachmentTextColor,
}: Props) => {
  const {body, source, created_at, metadata = {}} = message;
  const createdAt = dayjs.utc(created_at).local().format('ddd, MMM D h:mm A');
  // TODO: pull this from the conversation, or use the `message.subject` field instead
  const subject = metadata?.gmail_subject ?? metadata?.ses_subject ?? null;
  // TODO: add a `content_type` field to messages, which can be `text` or `html`
  const rawEmailHtml = metadata?.ses_html;
  const [formattedSource, sourceIcon] = getMessageSourceDetails(source);
  const parsedSx = Object.assign(sx, {
    px: 3,
    py: 2,
    borderRadius: 4,
    p: {mb: 0},
    ul: {my: 2},
    ol: {my: 2},
    blockquote: {
      px: 2,
      borderLeft: '3px solid',
      mb: 0,
    },
  });

  return (
    <Box sx={parsedSx}>
      {subject && (
        <Box pb={1} mb={2} sx={{borderBottom: '1px solid rgba(0,0,0,.06)'}}>
          <Text className={className} type="secondary" style={{fontSize: 12}}>
            {subject}
          </Text>
        </Box>
      )}

      {rawEmailHtml ? (
        // TODO: not sure the best way to handle this yet, but I think this is fine for now ¯\_(ツ)_/¯
        <div dangerouslySetInnerHTML={{__html: sanitizeHtml(rawEmailHtml)}} />
      ) : (
        <MarkdownRenderer className={className} source={body} />
      )}

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

      {formattedSource && (
        <Flex
          pt={1}
          mt={2}
          sx={{
            borderTop: '1px solid rgba(0,0,0,.06)',
            justifyContent: 'space-between',
            alignItems: 'center',
          }}
        >
          <Text
            className={className}
            type="secondary"
            style={{fontSize: 12, marginRight: 32}}
          >
            {createdAt}
          </Text>

          <Flex sx={{alignItems: 'center'}}>
            {sourceIcon && (
              <img
                src={sourceIcon}
                alt={source}
                style={{height: 12, marginRight: 4}}
              />
            )}
            <Text className={className} type="secondary" style={{fontSize: 12}}>
              Sent via {formattedSource}
            </Text>
          </Flex>
        </Flex>
      )}
    </Box>
  );
};

export default ChatMessageBox;
