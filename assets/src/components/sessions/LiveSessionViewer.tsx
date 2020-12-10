import React from 'react';
import {Link, RouteComponentProps} from 'react-router-dom';
import {throttle} from 'lodash';
import {Channel, Presence, Socket} from 'phoenix';
import {Box, Flex} from 'theme-ui';
import {Replayer, ReplayerEvents} from 'rrweb';
import {Alert, Button, Modal, Paragraph, Text, TextArea} from '../common';
import {ArrowLeftOutlined, SendOutlined} from '../icons';
import {SOCKET_URL} from '../../socket';
import * as API from '../../api';
import logger from '../../logger';
import Spinner from '../Spinner';
import ConversationDetailsSidebar from '../conversations/ConversationDetailsSidebar';
import ConversationSidebar from './ConversationSidebar';
import {Conversation, Customer} from '../../types';
import 'rrweb/dist/replay/rrweb-replay.min.css';

type Props = RouteComponentProps<{session: string}> & {};
type State = {
  loading: boolean;
  events: Array<any>;
  customer: Customer | null;
  conversation: Conversation | null;
  scale: number;
  isConversationModalOpen: boolean;
  isSendingMessage: boolean;
  isCustomerActive: boolean;
  isCustomerConnected: boolean;
  message: string;
};

class LiveSessionViewer extends React.Component<Props, State> {
  socket: Socket | null = null;
  channels: Array<Channel> = [];
  replayer!: Replayer; // TODO: start off as null?
  container: any;

  state: State = {
    loading: true,
    events: [],
    customer: null,
    conversation: null,
    scale: 1,
    isConversationModalOpen: false,
    isSendingMessage: false,
    isCustomerActive: true,
    isCustomerConnected: true,
    message: '',
  };

  // TODO: move a bunch of logic from here into separate functions
  async componentDidMount() {
    const {session: sessionId} = this.props.match.params;
    const {
      customer,
      account_id: accountId,
      customer_id: customerId,
    } = await API.fetchBrowserSession(sessionId);
    const conversation = await this.findExistingConversation(
      accountId,
      customerId
    );

    this.setState({customer, conversation});

    const root = document.getElementById('SessionPlayer') as Element;

    this.replayer = new Replayer([], {root: root, liveMode: true});
    this.replayer.on(ReplayerEvents.FullsnapshotRebuilded, () => {
      logger.debug('Full snapshot done!');
      // TODO: don't wait until this point to set `loading: false`...
      // we should probably do something like:
      // loading -> connecting to socket -> listening for events -> etc

      this.setIframeScale(() => this.setState({loading: false}));
    });

    // Socket connection below only necessary for live view
    this.socket = new Socket(SOCKET_URL, {
      params: {token: API.getAccessToken()},
    });

    this.socket.connect();
    // TODO: attempt refreshing access token?
    this.socket.onError(
      throttle(
        () =>
          logger.error('Error connecting to socket. Try refreshing the page.'),
        30 * 1000 // throttle every 30 secs
      )
    );

    this.listenForNewEvents(accountId, sessionId);
    this.listenForDisconnection(accountId, sessionId);

    window.addEventListener('resize', this.handleWindowResize);
  }

  componentWillUnmount() {
    window.removeEventListener('resize', this.handleWindowResize);

    if (this.replayer && this.replayer.pause) {
      this.replayer.pause();
    }

    if (this.channels && this.channels.length) {
      this.channels.map((ch) => ch.leave());
    }

    if (this.socket && this.socket.disconnect) {
      this.socket.disconnect();
    }
  }

  listenForNewEvents = (accountId: string, sessionId: string) => {
    if (!this.socket) {
      return;
    }

    const channel = this.socket.channel(
      `events:admin:${accountId}:${sessionId}`,
      {}
    );

    channel.on('replay:event:emitted', (data) => {
      logger.debug('New event emitted!', data);
      this.replayer.addEvent(data.event);
    });

    channel
      .join()
      .receive('ok', (res) => {
        logger.debug('Joined channel successfully', res);

        this.replayer.startLive();

        setTimeout(() => this.setIframeScale(), 100);
        setTimeout(() => this.setState({loading: false}), 60 * 1000);
      })
      .receive('error', (err) => {
        logger.error('Unable to join', err);
      });

    this.channels.push(channel);
  };

  listenForDisconnection = (accountId: string, sessionId: string) => {
    if (!this.socket) {
      return;
    }

    const channel = this.socket.channel(`events:admin:${accountId}:all`, {});

    channel
      .join()
      .receive('ok', (res: any) => {
        logger.debug('Joined session channel successfully!', res);
      })
      .receive('error', (err: any) => {
        logger.debug('Unable to join session channel!', err);
      });

    const presence = new Presence(channel);

    presence.onSync(() => {
      const records = presence.list().map(({metas}) => {
        const [info] = metas;

        return info;
      });
      const session = records.find((r) => r.session_id === sessionId);
      const isCustomerConnected = !!session;
      const isCustomerActive = isCustomerConnected && session.active;

      this.setState({isCustomerActive, isCustomerConnected});
    });

    this.channels.push(channel);
  };

  initializeNewConversation = async () => {
    const {customer, message} = this.state;

    if (!customer) {
      return null;
    }

    this.setState({isSendingMessage: true});

    try {
      const {id: customerId} = customer;
      const conversation = await API.createNewConversation(customerId, {
        message: {
          body: message,
          sent_at: new Date().toISOString(),
        },
      });

      this.setState({conversation});
    } catch (err) {
      logger.error('Failed to initialize conversation!', err);
    }

    this.setState({isConversationModalOpen: false, isSendingMessage: false});
  };

  handleOpenNewConversationModal = () =>
    this.setState({isConversationModalOpen: true});

  handleCloseNewConversationModal = () =>
    this.setState({isConversationModalOpen: false});

  findExistingConversation = async (
    accountId: string,
    customerId?: string | null
  ) => {
    if (!customerId) {
      return null;
    }

    const conversations = await API.fetchCustomerConversations(
      customerId,
      accountId
    );
    const [recent] = conversations;

    if (recent && recent.id) {
      return recent;
    }

    return null;
  };

  setIframeScale = (cb?: () => void) => {
    if (!this.replayer || !this.replayer.iframe) {
      this.setState({scale: 1}, cb);
    }

    const iframeWidth = Number(this.replayer.iframe.width);
    const iframeHeight = Number(this.replayer.iframe.height);
    const {
      clientWidth: containerWidth,
      clientHeight: containerHeight,
    } = this.container;
    const scaleX = containerWidth / iframeWidth;
    const scaleY = containerHeight / iframeHeight;
    logger.debug('Setting iframe scale:', {
      containerWidth,
      containerHeight,
      iframeWidth,
      iframeHeight,
      scaleX,
      scaleY,
    });
    const scale = scaleX < scaleY ? scaleX : scaleY;

    if (Number.isFinite(scale)) {
      this.setState({scale: scale || 1}, cb);
    } else {
      this.setState({scale: 1}, cb);
    }
  };

  handleWindowResize = () => {
    logger.debug('Handling resize...');
    this.setIframeScale();
  };

  renderStatusAlert() {
    const {loading, isCustomerConnected, isCustomerActive} = this.state;

    if (loading) {
      return (
        <Alert
          message={
            <Text>Loading the current session... this may take a minute.</Text>
          }
          type="info"
          showIcon
        />
      );
    } else if (!isCustomerConnected) {
      return (
        <Alert
          message={<Text>The customer has disconnected.</Text>}
          type="error"
          showIcon
        />
      );
    } else if (!isCustomerActive) {
      return (
        <Alert
          message={<Text>The customer is currently inactive.</Text>}
          type="warning"
          showIcon
        />
      );
    } else {
      return (
        <Alert
          message={<Text>The customer is currently active.</Text>}
          type="success"
          showIcon
        />
      );
    }
  }

  render() {
    const {
      loading,
      scale = 1,
      conversation,
      customer,
      isConversationModalOpen,
      isSendingMessage,
      isCustomerActive,
      isCustomerConnected,
      message,
    } = this.state;
    const hasAdditionalDetails = !!(conversation || customer);

    return (
      <Flex>
        <Box
          p={4}
          mr={hasAdditionalDetails ? 360 : 0}
          sx={{maxWidth: 960, width: '100%', flex: 1}}
        >
          <Box mb={4}>
            <Box mb={3}>
              <Paragraph>
                <Flex sx={{justifyContent: 'space-between'}}>
                  <Link to="/sessions/list">
                    <Button icon={<ArrowLeftOutlined />}>
                      Back to all sessions
                    </Button>
                  </Link>

                  {!loading && !conversation && (
                    <Button
                      type="primary"
                      onClick={this.handleOpenNewConversationModal}
                    >
                      Start conversation
                    </Button>
                  )}
                  <Modal
                    title="Initialize a conversation"
                    visible={isConversationModalOpen}
                    onCancel={this.handleCloseNewConversationModal}
                    footer={[
                      <Button
                        key="cancel"
                        onClick={this.handleCloseNewConversationModal}
                      >
                        Cancel
                      </Button>,
                      <Button
                        key="submit"
                        type="primary"
                        icon={<SendOutlined />}
                        loading={isSendingMessage}
                        onClick={this.initializeNewConversation}
                      >
                        Send
                      </Button>,
                    ]}
                  >
                    <TextArea
                      className="TextArea--transparent"
                      placeholder="Enter a message..."
                      autoSize={{maxRows: 4}}
                      autoFocus
                      value={message}
                      onChange={(e) => this.setState({message: e.target.value})}
                    />
                  </Modal>
                </Flex>
              </Paragraph>

              <Alert
                message={
                  <Text>
                    Note: This is an experimental feature! Let us know if you
                    notice any issues or bugs.
                  </Text>
                }
                type="warning"
                showIcon
              />

              <Box mt={3}>{this.renderStatusAlert()}</Box>
            </Box>
          </Box>

          <Flex className="rr-block" sx={{maxWidth: 960}}>
            <Box sx={{flex: 1, border: 'none'}}>
              {/* TODO: figure out the best way to style this */}
              {loading && (
                <Flex
                  sx={{
                    flex: 1,
                    justifyContent: 'center',
                    alignItems: 'center',
                    height: '100%',
                  }}
                >
                  <Spinner size={40} />
                </Flex>
              )}
              <Box
                mx={2}
                style={{
                  position: 'relative',
                  height: 480,
                  visibility: loading ? 'hidden' : 'visible',
                  opacity: isCustomerActive && isCustomerConnected ? 1 : 0.6,
                }}
                ref={(el) => (this.container = el)}
              >
                {/*
                  TODO: see https://github.com/rrweb-io/rrweb-player/blob/master/src/Player.svelte
                  for an example of how we could possibly style this better...
                */}
                <div
                  id="SessionPlayer"
                  style={{
                    transform: `scale(${scale})`,
                    transformOrigin: 'top left',
                  }}
                ></div>
              </Box>
            </Box>
          </Flex>
        </Box>

        {hasAdditionalDetails && (
          <Box
            sx={{
              width: 360,
              height: '100%',
              overflowY: conversation ? null : 'scroll',
              position: 'absolute',
              right: 0,
            }}
          >
            {conversation ? (
              <ConversationSidebar conversationId={conversation.id} />
            ) : customer ? (
              <ConversationDetailsSidebar customer={customer} />
            ) : null}
          </Box>
        )}
      </Flex>
    );
  }
}

export default LiveSessionViewer;
