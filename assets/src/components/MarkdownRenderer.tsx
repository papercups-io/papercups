import React from 'react';
import Markdown from 'react-markdown';
import remarkBreaks from 'remark-breaks';
import rehypeSanitize from 'rehype-sanitize';
import {Twemoji} from 'react-emoji-render';

// Allowed HTML elements (converted from markdown node types to HTML tags)
const allowedElements = [
  'p',
  'em',
  'strong',
  'blockquote',
  'del',
  'a',
  'ul',
  'ol',
  'li',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'code',
  'pre',
  'img',
  'br',
];

const components = {
  // Custom text renderer with emoji support
  p: ({children, ...props}: any) => {
    // Extract text content and wrap with Twemoji
    const textContent = React.Children.toArray(children)
      .map((child) => (typeof child === 'string' ? child : ''))
      .join('');

    if (textContent) {
      return (
        <p {...props}>
          <Twemoji text={textContent} />
        </p>
      );
    }
    return <p {...props}>{children}</p>;
  },
  img: (props: any) => {
    // TODO: fix scroll behavior after image loads
    return (
      <img
        alt={props.alt || ''}
        src={props.src}
        {...props}
        style={{maxWidth: '100%', maxHeight: 400}}
      />
    );
  },
};

type Props = {
  className?: string;
  source: string;
};

const MarkdownRenderer = ({className, source}: Props) => {
  return (
    <Markdown
      className={`Text--markdown ${className}`}
      allowedElements={allowedElements}
      components={components}
      remarkPlugins={[remarkBreaks]}
      rehypePlugins={[rehypeSanitize]}
    >
      {source}
    </Markdown>
  );
};

export default MarkdownRenderer;
