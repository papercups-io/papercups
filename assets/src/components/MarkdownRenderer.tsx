import React from 'react';
import ReactMarkdown from 'react-markdown';
import breaks from 'remark-breaks';
import {Twemoji} from 'react-emoji-render';
import {allowedNodeTypes} from './common';

const renderers = {
  text: (props: any) => {
    return <Twemoji text={props.children} />;
  },
  image: (props: any) => {
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
    <ReactMarkdown
      className={`Text--markdown ${className}`}
      source={source}
      allowedTypes={allowedNodeTypes}
      renderers={renderers}
      plugins={[breaks]}
    />
  );
};

export default MarkdownRenderer;
