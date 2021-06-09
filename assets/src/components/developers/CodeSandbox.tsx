import React from 'react';
import {Box, Flex} from 'theme-ui';
import request from 'superagent';

import {getRunKitCode, setRunKitCode} from '../../storage';
import {noop} from '../../utils';
import logger from '../../logger';
import {BASE_URL} from '../../config';
import {StandardSyntaxHighlighter} from '../common';
import RunKitWrapper from './RunKitWrapper';
import EmbeddableChat from './EmbeddableChat';
import {WEBHOOK_HANDLER_SOURCE} from './RunKit';

const CACHE_KEY = 'CodeSandbox';

type Props = {
  personalApiKey: string;
  accountId: string;
  onSuccess?: (output: any) => void;
  onError?: (error: any) => void;
};
type State = {
  runkit: any;
  output: any;
  isExecuting: boolean;
};

class CodeSandbox extends React.Component<Props, State> {
  state: State = {
    runkit: null,
    output: {message: 'Send a message in the chat to test.'},
    isExecuting: false,
  };

  handleRunKitLoaded = (runkit: any) => {
    this.setState({runkit});
  };

  handleRunKitOutput = (result: Record<any, any>) => {
    const {ok, data, error, message} = result;
    const {onSuccess = noop, onError = noop} = this.props;

    if (ok) {
      this.setState({output: {response: data}}, () => onSuccess(data));
    } else {
      this.setState({output: {error, message}}, () =>
        onError({error, message})
      );
    }

    // Cache source after running
    this.state.runkit
      .getSource()
      .then((source: string) => setRunKitCode(CACHE_KEY, source));
  };

  handleRunWebhookHandler = async (payload = {}) => {
    this.setState({isExecuting: true});

    const url = await this.state.runkit.getEndpointURL();
    logger.debug('Running webhook handler with url:', url);

    try {
      const result = await request
        .post(url)
        .send({
          event: 'message:created',
          payload,
        })
        .then((res) => res.body);

      this.handleRunKitOutput(result);
    } catch (error) {
      logger.error('Failed to run webhook handler:', error);

      this.handleRunKitOutput({
        ok: false,
        error: {
          ...error,
          message: [
            `Something went wrong! You may have a syntax error.`,
            `Try opening up ${url} in a new tab`,
            `to check for more helpful error messages.`,
          ],
        },
      });
    } finally {
      this.setState({isExecuting: false});
    }
  };

  render() {
    const {personalApiKey, accountId} = this.props;
    const {output = '', isExecuting} = this.state;

    return (
      <Flex sx={{width: '100%', maxHeight: 640}}>
        <Box sx={{flex: 1.2}}>
          <RunKitWrapper
            source={getRunKitCode(CACHE_KEY) || WEBHOOK_HANDLER_SOURCE}
            mode="endpoint"
            environment={[{name: 'PAPERCUPS_API_KEY', value: personalApiKey}]}
            minHeight={480}
            nodeVersion="14.x.x"
            onLoad={this.handleRunKitLoaded}
          />
        </Box>

        <Flex pl={2} sx={{flex: 1, flexDirection: 'column'}}>
          <EmbeddableChat
            sx={{height: 400, width: '100%'}}
            config={{
              accountId,
              primaryColor: '#1890ff',
              greeting: 'Send a message below to test your webhook handler!',
              baseUrl: BASE_URL,
            }}
            onMessageSent={this.handleRunWebhookHandler}
          />

          <Flex sx={{flex: 1, overflow: 'scroll'}}>
            <StandardSyntaxHighlighter
              language="json"
              style={{fontSize: 12, flex: 1}}
            >
              {isExecuting
                ? JSON.stringify({status: 'Running...'}, null, 2)
                : JSON.stringify(output, null, 2)}
            </StandardSyntaxHighlighter>
          </Flex>
        </Flex>
      </Flex>
    );
  }
}

export default CodeSandbox;
