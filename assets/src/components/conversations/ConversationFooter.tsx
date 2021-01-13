import React from 'react';
import {Box, Flex} from 'theme-ui';
import {colors, Button, Menu, TextArea} from '../common';
import {Message, MessageType} from '../../types';

const ConversationFooter = ({
  sx = {},
  onSendMessage,
}: {
  sx?: any;
  onSendMessage: (message: Partial<Message>) => void;
}) => {
  const [message, setMessage] = React.useState<string>('');
  const [messageType, setMessageType] = React.useState<MessageType>('reply');

  const isPrivateNote = messageType === 'note';

  const handleMessageChange = (e: React.ChangeEvent<HTMLTextAreaElement>) =>
    setMessage(e.target.value);

  const handleSetMessageType = ({key}: any) => setMessageType(key);

  const handleKeyDown = (e: any) => {
    const {key, metaKey} = e;
    // Not sure what the best UX is here, but we currently allow
    // sending the message by pressing "cmd/metaKey + Enter"
    if (metaKey && key === 'Enter') {
      handleSendMessage();
    }
  };

  const handleSendMessage = (e?: any) => {
    e && e.preventDefault();

    onSendMessage({
      body: message,
      type: messageType,
      private: isPrivateNote,
    });

    setMessage('');
  };

  return (
    <Box style={{flex: '0 0 auto'}}>
      <Box
        sx={{
          bg: colors.white,
          px: 4,
          pt: 0,
          pb: 4,
          ...sx,
        }}
      >
        <Box
          px={2}
          pb={2}
          pt={1}
          sx={{
            background: isPrivateNote ? 'rgba(254,237,175,.5)' : colors.white,
            border: '1px solid #f5f5f5',
            borderRadius: 4,
            boxShadow: 'rgba(0, 0, 0, 0.1) 0px 0px 8px',
          }}
        >
          <form onSubmit={handleSendMessage}>
            <Box px={2} mb={2}>
              <Menu
                mode="horizontal"
                style={{
                  border: 'none',
                  lineHeight: '36px',
                  fontWeight: 500,
                  background: 'transparent',
                  color: colors.secondary,
                }}
                defaultSelectedKeys={['reply']}
                selectedKeys={[messageType]}
                onClick={handleSetMessageType}
              >
                <Menu.Item
                  key="reply"
                  style={{padding: '0 4px', marginRight: 20}}
                >
                  Reply
                </Menu.Item>
                <Menu.Item
                  key="note"
                  style={{padding: '0 4px', marginRight: 20}}
                >
                  Note
                </Menu.Item>
              </Menu>
            </Box>

            <Box mb={2}>
              <TextArea
                className="TextArea--transparent"
                placeholder="Type your message here"
                autoSize={{minRows: 2, maxRows: 4}}
                autoFocus
                value={message}
                onKeyDown={handleKeyDown}
                onChange={handleMessageChange}
              />
            </Box>
            <Flex sx={{justifyContent: 'flex-end'}}>
              <Button type="primary" htmlType="submit">
                Send
              </Button>
            </Flex>
          </form>
        </Box>
      </Box>
    </Box>
  );
};

export default ConversationFooter;
