import React from 'react';
import {Box, Image} from 'theme-ui';
import SyntaxHighlighter from 'react-syntax-highlighter';
import {atomOneLight} from 'react-syntax-highlighter/dist/esm/styles/hljs';
import * as API from '../../api';
import {User} from '../../types';
import {Paragraph, colors, Text, Title} from '../common';
import {BASE_URL} from '../../config';

type Props = {};
type State = {
  accountId: string | null;
  currentUser: User | null;
};

class InstallingStorytime extends React.Component<Props, State> {
  state: State = {
    accountId: null,
    currentUser: null,
  };

  async componentDidMount() {
    const currentUser = await API.me();
    const account = await API.fetchAccountInfo();
    const {id: accountId} = account;

    this.setState({
      accountId,
      currentUser,
    });
  }

  generateHtmlCode = () => {
    const {accountId} = this.state;

    return `
<script>
  // NOTE: DO NOT copy the window.Papercups.config again if you
  // have already installed the chat widget — otherwise it will
  // override your chat widget settings and cause problems!
  window.Papercups = {
    config: {
      accountId: "${accountId}",

      // Optionally pass in metadata to identify the customer
      // customer: {
      //  name: "Test User",
      //  email: "test@test.com",
      //  external_id: "123",
      // },

      // Optionally specify the base URL
      baseUrl: "${BASE_URL}"
    },
  };
</script>
<script
  type="text/javascript"
  async
  defer
  src="${BASE_URL}/storytime.js"
></script>
  `.trim();
  };

  generateSimpleHtmlCode = () => {
    return `
<script
  type="text/javascript"
  async
  defer
  src="${BASE_URL}/storytime.js"
></script>
  `.trim();
  };

  generateModuleCode = () => {
    const {accountId} = this.state;

    return `
import {Storytime} from '@papercups-io/storytime';

const st = Storytime.init({
  accountId: '${accountId}',

  // Optionally pass in metadata to identify the customer
  // customer: {
  //  name: 'Test User',
  //  email: 'test@test.com',
  //  external_id: '123',
  // },

  // Optionally specify the base URL
  baseUrl: '${BASE_URL}',
});

// If you want to stop the session recording manually, you can call:
// st.finish();

// Otherwise, the recording will stop as soon as the user exits your website.
  `.trim();
  };

  render() {
    const {accountId} = this.state;

    if (!accountId) {
      return null; // TODO: better loading state
    }

    return (
      <Box
        p={4}
        sx={{
          maxWidth: 720,
        }}
      >
        <Box mb={4}>
          <Title>Set up Storytime</Title>
          <Paragraph>
            <Text>
              Before you can start viewing your customers' sessions, you'll need
              to install our plugin on your website.
            </Text>
          </Paragraph>

          <Box>
            <Image src="https://user-images.githubusercontent.com/5264279/96898977-56c27d00-145e-11eb-907b-ca8db13a0fa0.gif" />
          </Box>
        </Box>

        <Box mb={4}>
          <Title level={3}>Installing the plugin</Title>
          <Paragraph>
            <Text>
              There are two ways you can install the plugin: in HTML, or via
              importing as a module.
            </Text>
          </Paragraph>
        </Box>

        <Box mb={4}>
          <Title level={3}>Usage in HTML</Title>
          <Paragraph>
            <Text>
              Paste the code below between your <Text code>{'<head>'}</Text> and{' '}
              <Text code>{'</head>'}</Text> tags:
            </Text>
          </Paragraph>

          <SyntaxHighlighter language="html" style={atomOneLight}>
            {this.generateHtmlCode()}
          </SyntaxHighlighter>

          <Paragraph>
            <Text strong mark>
              Note that if you've already installed the chat widget, you will
              only need to add this script below it:
            </Text>
          </Paragraph>

          <SyntaxHighlighter language="html" style={atomOneLight}>
            {this.generateSimpleHtmlCode()}
          </SyntaxHighlighter>
        </Box>

        <Box mb={4}>
          <Title level={3}>Usage with NPM module</Title>
          <Paragraph>
            <Text>
              First, install the <Text code>@papercups-io/storytime</Text>{' '}
              package:
            </Text>
          </Paragraph>

          <Paragraph>
            <pre
              style={{
                backgroundColor: '#f6f8fa',
                color: colors.black,
                fontSize: 12,
              }}
            >
              <Box p={3}>npm install --save @papercups-io/storytime</Box>
            </pre>
          </Paragraph>

          <Paragraph>
            <Text>
              Your account token has been prefilled in the code below. Simply
              copy and paste the code into the root of your app, or into
              whichever components you would like to track!
            </Text>
          </Paragraph>

          <SyntaxHighlighter language="typescript" style={atomOneLight}>
            {this.generateModuleCode()}
          </SyntaxHighlighter>
        </Box>

        <Title level={3}>Learn more</Title>
        <Paragraph>
          <Text>
            See the code and star our{' '}
            <a
              href="https://github.com/papercups-io/storytime"
              target="_blank"
              rel="noopener noreferrer"
            >
              Github repo
            </a>
            .
          </Text>
        </Paragraph>
      </Box>
    );
  }
}

export default InstallingStorytime;
