import React from 'react';
import {Box, Flex} from 'theme-ui';
import * as API from '../../api';
import GettingStarted from './GettingStarted';

type Props = {};
type State = {
  account: any;
};

class GettingStartedOverview extends React.Component<Props, State> {
  state: State = {account: null};

  async componentDidMount() {
    const account = await API.fetchAccountInfo();

    this.setState({account});
  }
  render() {
    const {account} = this.state;

    if (!account || !account.id) {
      return null;
    }

    return (
      <Box p={4}>
        <GettingStarted accountId={account.id} />
      </Box>
    );
  }
}

export default GettingStartedOverview;
