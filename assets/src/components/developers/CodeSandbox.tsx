import React from 'react';
import {Box, Flex} from 'theme-ui';
import request from 'superagent';

import {noop} from '../../utils';
import logger from '../../logger';
import {BASE_URL} from '../../config';
import {Divider, StandardSyntaxHighlighter, Text} from '../common';
import RunKitWrapper from './RunKitWrapper';
import EmbeddableChat from './EmbeddableChat';
import {WEBHOOK_HANDLER_SOURCE} from './RunKit';

export type SidebarProps = {
  accountId: string;
  isExecuting: boolean;
  output: any;
  onRunHandler: (payload: any) => void;
};

const DefaultSidebar = ({
  accountId,
  output,
  isExecuting,
  onRunHandler,
}: SidebarProps) => {
  return (
    <Flex pl={2} sx={{flex: 1, flexDirection: 'column'}}>
      <EmbeddableChat
        sx={{height: 360, width: '100%'}}
        config={{
          accountId,
          primaryColor: '#1890ff',
          greeting: 'Send a message below to test your webhook handler!',
          newMessagePlaceholder: 'Send a test message...',
          baseUrl: BASE_URL,
        }}
        onMessageSent={onRunHandler}
      />

      <Divider />

      <Flex sx={{flex: 1, flexDirection: 'column', overflow: 'scroll'}}>
        <Box>
          <Text strong>Output:</Text>
        </Box>
        <StandardSyntaxHighlighter
          language="json"
          style={{fontSize: 12, flex: 1, minHeight: 80}}
        >
          {isExecuting
            ? JSON.stringify({status: 'Running...'}, null, 2)
            : JSON.stringify(output, null, 2)}
        </StandardSyntaxHighlighter>
      </Flex>
    </Flex>
  );
};

type Props = {
  personalApiKey: string;
  accountId: string;
  code?: string;
  defaultHeight?: number;
  sidebar?: (opts: SidebarProps) => React.ReactElement;
  footer?: (opts: SidebarProps) => React.ReactElement;
  onLoad?: (runkit: any) => void;
  onSuccess?: (output: any) => void;
  onError?: (error: any) => void;
};
type State = {
  runkit: any;
  runkitIframeHeight: number;
  name: string;
  description: string;
  output: any;
  isExecuting: boolean;
};

export class CodeSandbox extends React.Component<Props, State> {
  state: State = {
    runkit: null,
    runkitIframeHeight: this.props.defaultHeight || 720, // default
    name: 'Untitled function',
    description: '',
    output: {
      response: null,
      tip: 'Send a message above to test your handler.',
    },
    isExecuting: false,
  };

  handleRunKitLoaded = (runkit: any) => {
    this.setState({runkit});
    this.props.onLoad && this.props.onLoad(runkit);
  };

  handleRunKitResize = (runkit: any) => {
    const name = runkit?.name;

    if (!name) {
      return;
    }

    const el = document.querySelector(`iframe[name=${name}]`);

    if (el && el.clientHeight) {
      this.setState({runkitIframeHeight: el.clientHeight});
    }
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

    // // Cache source after running?
    // this.state.runkit
    //   .getSource()
    //   .then((source: string) => setRunKitCode(CACHE_KEY, source));
  };

  handleRunWebhookHandler = async (payload = {}) => {
    this.setState({isExecuting: true});

    const url = await this.state.runkit.getEndpointURL();
    logger.debug('Running webhook handler with url:', url);

    try {
      const result = await request
        .post(url)
        .send({
          // TODO: support testing other webhook event types
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
    const {personalApiKey, accountId, code} = this.props;
    const {output = '', runkitIframeHeight = 720, isExecuting} = this.state;

    return (
      <Flex sx={{width: '100%', maxHeight: runkitIframeHeight}}>
        <Box sx={{flex: 1.2, position: 'relative'}}>
          <RunKitWrapper
            source={code || WEBHOOK_HANDLER_SOURCE}
            mode="endpoint"
            environment={[{name: 'PAPERCUPS_API_KEY', value: personalApiKey}]}
            minHeight={runkitIframeHeight}
            nodeVersion="14.x.x"
            onLoad={this.handleRunKitLoaded}
            onResize={this.handleRunKitResize}
          />
          {typeof this.props.footer === 'function'
            ? this.props.footer({
                output,
                accountId,
                isExecuting,
                onRunHandler: this.handleRunWebhookHandler,
              })
            : null}
        </Box>

        {typeof this.props.sidebar === 'function' ? (
          this.props.sidebar({
            output,
            accountId,
            isExecuting,
            onRunHandler: this.handleRunWebhookHandler,
          })
        ) : (
          <DefaultSidebar
            accountId={accountId}
            isExecuting={isExecuting}
            output={output}
            onRunHandler={this.handleRunWebhookHandler}
          />
        )}
      </Flex>
    );
  }
}

export default CodeSandbox;
