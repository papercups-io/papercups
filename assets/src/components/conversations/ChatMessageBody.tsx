import React from 'react';
import DOMPurify from 'dompurify';
import marked from 'marked';

const ChatMessageBody = ({body}: {body: string}) => {
  const markupBody = DOMPurify.sanitize(marked(body));
  return <span dangerouslySetInnerHTML={{__html: markupBody}} />;
};

export default ChatMessageBody;
