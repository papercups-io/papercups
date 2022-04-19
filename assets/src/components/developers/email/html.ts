import {JS_COMPONENTS} from './components';
import {getDefaultCss, getPremailerIgnoredCss} from './styles';

export const getIframeContents = ({
  css,
  cssPremailerIgnore,
  js,
}: {
  css?: string;
  cssPremailerIgnore?: string;
  js: string;
}) => {
  return `
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <style type="text/css">
      ${getDefaultCss() || css}
    </style>
    <style type="text/css" data-premailer="ignore">
      ${getPremailerIgnoredCss() || cssPremailerIgnore}
    </style>
  </head>
  <body>
    <script src="https://unpkg.com/react@16/umd/react.development.js" crossorigin></script>
    <script src="https://unpkg.com/react-dom@16/umd/react-dom.development.js" crossorigin></script>
    <script src="https://unpkg.com/react-markdown@4.1.0/umd/react-markdown.js" crossorigin></script>
    <script src="https://unpkg.com/babel-standalone@6/babel.min.js"></script>

    <div id="email"></div>

    <script type="text/babel">
      'use strict';

      ${JS_COMPONENTS}

      // const Email = (props) => {...}
      ${js}

      ReactDOM.render(<Email />, document.querySelector('#email'));
    </script>
  </body>
  </html>
  `;
};
