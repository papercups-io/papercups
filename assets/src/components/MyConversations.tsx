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

class MyConversations extends React.Component<Props, State> {
  state: any = {
    account: null,
    currentUser: null,
    conversations: [],
    loading: true,
  };

  async componentDidMount() {
    try {
      const user = await API.me();
      const account = await API.fetchAccountInfo();

      this.setState({
        account,
        currentUser: user,
        loading: false,
      });
    } catch (err) {
      console.log('Error loading my conversations!', err);

      this.setState({loading: false});
    }
  }

  handleFetchConversations = () => {
    const {currentUser} = this.state;
    const {id: userId} = currentUser;

    return API.fetchMyConversations(userId);
  };

  render() {
    const {account, currentUser, conversations, loading} = this.state;

    if (loading || !account || !currentUser) {
      // TODO: handle loading state
      return null;
    }

    return (
      <ConversationsContainer
        title="Assigned to me"
        account={account}
        currentUser={currentUser}
        conversations={conversations}
        fetch={this.handleFetchConversations}
      />
    );
  }
}

export default MyConversations;
