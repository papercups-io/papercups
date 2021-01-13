import React from 'react';
import {Box, Flex} from 'theme-ui';
import {colors, Button, TextArea} from '../common';

const ConversationFooter = ({
  sx = {},
  onSendMessage,
}: {
  sx?: any;
  onSendMessage: (message: string) => void;
}) => {
  const [message, setMessage] = React.useState('');

  const handleMessageChange = (e: React.ChangeEvent<HTMLTextAreaElement>) =>
    setMessage(e.target.value);

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
    onSendMessage(message);
    setMessage('');
  };

  return (
    <Box style={{flex: '0 0 auto'}}>
      <Box sx={{bg: colors.white, px: 4, pt: 0, pb: 4, ...sx}}>
        <Box
          p={2}
          sx={{
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
