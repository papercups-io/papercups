import React from 'react';
import {Box, Flex} from 'theme-ui';
import request from 'superagent';

import {Button, StandardSyntaxHighlighter} from '../common';
import {getRunKitCode, setRunKitCode} from '../../storage';
import {noop} from '../../utils';
import RunKitWrapper from './RunKitWrapper';
import {DEFAULT_RUNKIT_SOURCE} from './RunKit';
import logger from '../../logger';

const CACHE_KEY = 'ApiExplorer';

type Props = {
  personalApiKey: string;
  onSuccess?: (output: any) => void;
  onError?: (error: any) => void;
};
type State = {
  runkit: any;
  output: any;
  isExecuting: boolean;
};

class ApiExplorer extends React.Component<Props, State> {
  state: State = {
    runkit: null,
    output: {message: 'Click the button above to run your code.'},
    isExecuting: false,
  };

  handleRunKitLoaded = (runkit: any) => {
    this.setState({runkit});
  };

  handleRunKitOutput = (result: Record<any, any>) => {
    const {ok, data, error, message} = result;
    const {onSuccess = noop, onError = noop} = this.props;

    if (ok) {
      this.setState({output: data}, () => onSuccess(data));
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

  handleRunScript = async () => {
    this.setState({isExecuting: true});

    const url = await this.state.runkit.getEndpointURL();
    logger.debug('Running script with url:', url);

    try {
      const result = await request
        .get(url)
        .query({})
        .then((res) => res.body);

      this.handleRunKitOutput(result);
    } catch (error) {
      logger.error('Failed to run script:', error);

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
    const {personalApiKey} = this.props;
    const {output = '', isExecuting} = this.state;

    return (
      <Flex sx={{width: '100%', maxHeight: 520}}>
        <Box sx={{flex: 1}}>
          <RunKitWrapper
            source={getRunKitCode(CACHE_KEY) || DEFAULT_RUNKIT_SOURCE}
            mode="endpoint"
            environment={[{name: 'PAPERCUPS_API_KEY', value: personalApiKey}]}
            minHeight={480}
            nodeVersion="14.x.x"
            onLoad={this.handleRunKitLoaded}
          />
        </Box>

        <Flex pl={2} sx={{flex: 1, flexDirection: 'column'}}>
          <Box>
            <Button
              block
              type="primary"
              loading={isExecuting}
              onClick={this.handleRunScript}
            >
              {isExecuting
                ? 'Running your code...'
                : 'Execute code in `run` function'}
            </Button>
          </Box>

          <Flex sx={{flex: 1, overflow: 'scroll'}}>
            <StandardSyntaxHighlighter
              language="json"
              style={{fontSize: 12, flex: 1}}
            >
              {JSON.stringify(output, null, 2)}
            </StandardSyntaxHighlighter>
          </Flex>
        </Flex>
      </Flex>
    );
  }
}

export default ApiExplorer;
