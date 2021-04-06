import React from 'react';

import {Button, Modal, TextArea, Tooltip} from '../common';
import {SendOutlined} from '../icons';
import * as API from '../../api';
import logger from '../../logger';
import {Conversation} from '../../types';
import {TooltipPlacement} from 'antd/lib/tooltip';

export type Props = {
  customerId: string;
  disabled: boolean;
  disabledTooltipPlacement: TooltipPlacement;
  disabledTooltipTitle: string;
  onInitializeNewConversation?: (conservation: Conversation) => void;
};

export type State = {
  isConversationModalOpen: boolean;
  isSendingMessage: boolean;
  message: string;
};

export class StartConversationButton extends React.Component<Props, State> {
  static defaultProps = {
    disabled: false,
    disabledTooltipPlacement: 'right',
    disabledTooltipTitle: 'This customer already has an open conversation',
  };

  state: State = {
    isConversationModalOpen: false,
    isSendingMessage: false,
    message: '',
  };

  handleOpenNewConversationModal = () => {
    this.setState({isConversationModalOpen: true});
  };

  handleCloseNewConversationModal = () => {
    this.setState({isConversationModalOpen: false});
  };

  initializeNewConversation = async () => {
    const {customerId, onInitializeNewConversation} = this.props;
    const {message} = this.state;

    this.setState({isSendingMessage: true});

    try {
      const conversation = await API.createNewConversation(customerId, {
        message: {
          body: message,
          sent_at: new Date().toISOString(),
        },
      });

      if (onInitializeNewConversation) {
        onInitializeNewConversation(conversation);
      }
    } catch (err) {
      logger.error('Failed to initialize conversation!', err);
    }

    this.setState({isConversationModalOpen: false, isSendingMessage: false});
  };

  getButton = () => {
    const {
      disabled,
      disabledTooltipPlacement,
      disabledTooltipTitle,
    } = this.props;

    const button = (
      <Button
        type="primary"
        onClick={this.handleOpenNewConversationModal}
        disabled={disabled}
      >
        Start conversation
      </Button>
    );

    if (disabled) {
      return (
        <Tooltip
          title={disabledTooltipTitle}
          placement={disabledTooltipPlacement}
        >
          {button}
        </Tooltip>
      );
    } else {
      return button;
    }
  };

  render() {
    const {isConversationModalOpen, isSendingMessage, message} = this.state;

    return (
      <React.Fragment>
        {this.getButton()}
        <Modal
          title="Initialize a conversation"
          visible={isConversationModalOpen}
          onCancel={this.handleCloseNewConversationModal}
          footer={[
            <Button key="cancel" onClick={this.handleCloseNewConversationModal}>
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
      </React.Fragment>
    );
  }
}

export default StartConversationButton;
