import React from 'react';
import {Box, Flex} from 'theme-ui';
import {colors, Button, TextArea, Radio, Space} from '../common';

const ConversationFooter = ({
  sx = {},
  onSendMessage,
}: {
  sx?: any;
  onSendMessage: (message: string, messageType: string, priv: boolean) => void;
}) => {
  const [message, setMessage] = React.useState('');
  const [messageType, setMessageType] = React.useState('reply');

  const handleMessageChange = (e: any) => setMessage(e.target.value);

  const handleKeyDown = (e: any) => {
    const {key, metaKey} = e;
    // Not sure what the best UX is here, but we currently allow
    // sending the message by pressing "cmd/metaKey + Enter"
    if (metaKey && key === 'Enter') {
      handleSendMessage();
    }
  };

  const handleSendMessage = (e?: any) => {
    const priv = messageType == 'note' ? true : false;
    e && e.preventDefault();
    onSendMessage(message, messageType, priv);
    setMessage('');
  };

  const handleTypeChange = (e: any) => {
    setMessageType(e.target.value);
  };

  return (
    <Box style={{flex: '0 0 auto'}}>
      <Box sx={{bg: colors.white, px: 4, pt: 0, pb: 4, ...sx}}>
        <Box
          p={2}
          sx={{
            bg: messageType == 'reply' ? colors.white : '#FEF6D7',
            border: '1px solid #f5f5f5',
            borderRadius: 4,
            boxShadow: 'rgba(0, 0, 0, 0.1) 0px 0px 8px',
          }}
        >
          <form onSubmit={handleSendMessage}>
            <Box mb={2}>
              <TextArea
                className="TextArea--transparent"
                placeholder="Type your message here!"
                autoSize={{maxRows: 4}}
                autoFocus
                value={message}
                onKeyDown={handleKeyDown}
                onChange={handleMessageChange}
                style={{
                  backgroundColor:
                    messageType == 'reply' ? colors.white : '#FEF6D7',
                }}
              />
            </Box>
            <Flex sx={{alignItems: 'center'}}>
              <Radio.Group
                value={messageType}
                size="small"
                onChange={handleTypeChange}
              >
                <Space>
                  <Radio.Button value="reply">Reply</Radio.Button>
                  <Radio.Button value="note">Note</Radio.Button>
                </Space>
              </Radio.Group>
              <Button
                type="primary"
                htmlType="submit"
                style={{marginLeft: 'auto'}}
              >
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
