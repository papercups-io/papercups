import React from 'react';
import {RouteComponentProps} from 'react-router-dom';
import * as API from '../api';
import {Conversation} from '../types';
import ConversationsContainer from './ConversationsContainer';

type Props = RouteComponentProps & {};
type State = {
  account: any;
  currentUser: any;
  conversations: Array<Conversation>;
  loading: boolean;
};

class ClosedConversations extends React.Component<Props, State> {
  state: any = {
    account: null,
    currentUser: null,
    conversations: [],
    loading: true,
  };

  componentDidMount() {
    const promises = [
      // TODO: do in AuthProvider
      API.me()
        .then((user) => this.setState({currentUser: user}))
        .catch((err) => console.log('Error fetching current user:', err)),

      // TODO: handle in a different context?
      API.fetchAccountInfo()
        .then((account) => this.setState({account}))
        .catch((err) => console.log('Error fetching account info:', err)),

      API.fetchClosedConversations()
        .then((conversations) => this.setState({conversations}))
        .catch((err) => console.log('Error fetching conversations:', err)),
    ];

    Promise.all(promises).then(() => this.setState({loading: false}));
  }

  render() {
    const {account, currentUser, conversations, loading} = this.state;

    if (loading || !account || !currentUser) {
      // TODO: handle loading state
      return null;
    }

    return (
      <ConversationsContainer
        title="Closed"
        account={account}
        currentUser={currentUser}
        conversations={conversations}
      />
    );
  }
}

export default ClosedConversations;
