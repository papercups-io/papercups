import React from 'react';
import {Box, Flex, SxStyleProp} from 'theme-ui';
import {
  ChatBuilder,
  ChatFooter,
  BodyProps,
  Config,
} from '@papercups-io/chat-builder';
import {Message} from '../../types';
import {MarkdownRenderer} from '../common';

const CustomerMessage = ({
  message,
  color,
  isNextSameSender,
}: {
  message: Message;
  color?: string;
  isNextSameSender: boolean;
}) => {
  return (
    <Box
      sx={{
        display: 'flex',
        paddingBottom: isNextSameSender ? 2 : 3,
        paddingLeft: 48,
        paddingRight: 0,
        justifyContent: 'flex-end',
      }}
    >
      <Box
        sx={{
          fontSize: 14,
          padding: '12px 16px',
          background: color || 'rgb(24, 144, 255)',
          color: '#fff',
          whiteSpace: 'pre-wrap',
          transition: 'background 0.4s ease',
          borderRadius: 5,
          p: {
            mb: 0,
          },
          blockquote: {
            px: 2,
            borderLeft: '3px solid',
            mb: 0,
          },
        }}
      >
        <MarkdownRenderer source={message.body} />
      </Box>
    </Box>
  );
};

const AgentMessage = ({
  message,
  isNextSameSender,
}: {
  message: Message;
  isNextSameSender: boolean;
}) => {
  const profilePhotoUrl =
    message.user?.profile_photo_url ||
    'https://avatars.slack-edge.com/2021-01-13/1619416452487_002cddd7d8aea1950018_192.png';
  const shouldDisplayAvatar = !isNextSameSender;

  return (
    <Box
      sx={{
        display: 'flex',
        position: 'relative',
        paddingBottom: isNextSameSender ? 2 : 3,
        paddingLeft: 44,
        paddingRight: 48,
        justifyContent: 'flex-start',
        alignItems: 'flex-end',
      }}
    >
      {shouldDisplayAvatar && (
        <Box
          sx={{
            height: 32,
            width: 32,
            position: 'absolute',
            left: 0,
            bottom: 20,

            borderRadius: '50%',
            justifyContent: 'center',
            alignItems: 'center',

            backgroundPosition: 'center',
            backgroundSize: 'cover',
            backgroundImage: `url(${profilePhotoUrl})`,
          }}
        />
      )}

      <Box
        sx={{
          fontSize: 14,
          padding: '12px 16px',
          background: 'rgb(245, 245, 245)',
          color: 'rgba(0,0,0,.65)',
          whiteSpace: 'pre-wrap',
          borderRadius: 5,
          p: {
            mb: 0,
          },
          blockquote: {
            px: 2,
            borderLeft: '3px solid',
            mb: 0,
          },
        }}
      >
        <MarkdownRenderer source={message.body} />
      </Box>
    </Box>
  );
};

const Body = ({state, config, scrollToRef}: BodyProps) => {
  const {customerId, messages = []} = state;
  const {primaryColor: color} = config;

  return (
    <div style={{padding: '16px 16px'}}>
      {messages.map((message: any, idx: number) => {
        const isCustomer =
          message.customer_id === customerId ||
          (!!message.sent_at && message.type === 'customer');
        const next = messages[idx + 1];
        const isNextMessageCustomer =
          next &&
          (next.customer_id === customerId ||
            (!!next.sent_at && next.type === 'customer'));
        const isNextSameSender = isCustomer === isNextMessageCustomer;

        if (isCustomer) {
          return (
            <CustomerMessage
              key={message.id || idx}
              message={message}
              color={color}
              isNextSameSender={isNextSameSender}
            />
          );
        } else {
          return (
            <AgentMessage
              key={message.id || idx}
              message={message}
              isNextSameSender={isNextSameSender}
            />
          );
        }
      })}

      <div key="scroll-el" ref={scrollToRef} />
    </div>
  );
};

const EmbeddableChat = ({
  config,
  height,
  width,
  sx = {},
  onChatLoaded,
  onMessageSent,
  onMessageReceived,
}: {
  config: Config;
  height?: number | string;
  width?: number | string;
  sx?: SxStyleProp;
  onChatLoaded?: (papercups: any) => void;
  onMessageSent?: (message: any) => void;
  onMessageReceived?: (message: any) => void;
}) => {
  return (
    <ChatBuilder
      config={config}
      scrollIntoViewOptions={{
        block: 'nearest',
        inline: 'start',
      }}
      onChatLoaded={onChatLoaded}
      onMessageSent={onMessageSent}
      onMessageReceived={onMessageReceived}
    >
      {({config, state, scrollToRef, onSendMessage}) => {
        const handleSendMessage = (message: any, email?: string) => {
          const {metadata = {}} = message;

          return onSendMessage(
            {
              ...message,
              // TODO: make this configurable as a prop
              metadata: {...metadata, disable_webhook_events: true},
            },
            email
          );
        };

        return (
          <Box
            sx={{
              height: height || 560,
              width: width || 376,
              border: '1px solid rgb(230, 230, 230)',
              borderRadius: 4,
              overflow: 'hidden',
              ...sx,
            }}
          >
            <Flex
              style={{
                background: '#fff',
                flexDirection: 'column',
                height: '100%',
                width: '100%',
                flex: 1,
              }}
            >
              <Box
                style={{
                  flex: 1,
                  overflowY: 'scroll',
                }}
              >
                <Body config={config} state={state} scrollToRef={scrollToRef} />
              </Box>

              <ChatFooter
                config={config}
                state={state}
                onSendMessage={handleSendMessage}
              />
            </Flex>
          </Box>
        );
      }}
    </ChatBuilder>
  );
};

export default EmbeddableChat;
