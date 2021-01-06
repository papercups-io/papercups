import React from 'react';
import {Box, Flex} from 'theme-ui';
import {colors, Button, TextArea} from '../common';

const ConversationFooter = ({
  sx = {},
  onSendMessage,
  onInputChanged,
  othersTyping,
}: {
  sx?: any;
  onSendMessage: (message: string) => void;
  onInputChanged: () => void;
  othersTyping: Array<object>;
}) => {
  const [message, setMessage] = React.useState('');

  const handleMessageChange = (e: any) => setMessage(e.target.value);

  const handleKeyDown = (e: any) => {
    onInputChanged();

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

  const othersTypingMessage = (others: Array<any>) => {
    const toStr = (name?: string, email?: string) =>
      `${name || email || 'Anonymous User'} `;

    const titles = others.map((item: any) => toStr(item.name, item.email));

    switch (titles.length) {
      case 0:
        return '\xa0';
      case 1:
        return [...titles, 'is typing...'].join(' ');
      default:
        return `${titles.join(', ')} are typing...`;
    }
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
                autoSize={{maxRows: 4}}
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
        <Box sx={{position: 'absolute'}}>
          {othersTypingMessage(othersTyping)}
        </Box>
      </Box>
    </Box>
  );
};

export default ConversationFooter;
