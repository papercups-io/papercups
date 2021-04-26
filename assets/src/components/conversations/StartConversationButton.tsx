import React from 'react';
import {Box} from 'theme-ui';
import {TooltipPlacement} from 'antd/lib/tooltip';

import {
  Button,
  Divider,
  Input,
  Modal,
  Select,
  TextArea,
  Tooltip,
} from '../common';
import {SendOutlined} from '../icons';
import * as API from '../../api';
import logger from '../../logger';
import {Conversation, ConversationSource} from '../../types';

const DEFAULT_CONVERSATION_SOURCE: ConversationSource = 'chat';

const NewConversationModal = ({
  visible,
  onCancel,
  onSuccess,
}: {
  visible: boolean;
  onCancel: () => void;
  onSuccess: (params: Record<any, any>) => Promise<any>;
}) => {
  const [source, setConversationSource] = React.useState<ConversationSource>(
    DEFAULT_CONVERSATION_SOURCE
  );
  const [subject, setSubject] = React.useState('');
  const [message, setMessage] = React.useState('');
  const [isSending, setSending] = React.useState(false);

  const handleSendMessage = async () => {
    setSending(true);

    await onSuccess({
      source,
      subject,
      message: {
        body: message,
        sent_at: new Date().toISOString(),
      },
    });

    setSending(false);
  };

  return (
    <Modal
      title="Start a new conversation"
      visible={visible}
      onCancel={onCancel}
      footer={[
        <Button key="cancel" onClick={onCancel}>
          Cancel
        </Button>,
        <Button
          key="submit"
          type="primary"
          icon={<SendOutlined />}
          loading={isSending}
          onClick={handleSendMessage}
        >
          {isSending ? 'Sending' : 'Send'} as {source}
        </Button>,
      ]}
    >
      <Box>
        <Box>
          {/* TODO: not sure if a select input is the best UX here... */}
          <Select
            id="icon_variant"
            style={{width: 240}}
            value={source}
            onChange={setConversationSource}
            options={['chat', 'email'].map((variant) => {
              return {value: variant, label: `Send as ${variant}`};
            })}
          />
        </Box>

        <Divider />

        {source === 'email' && (
          <Box mb={3}>
            <Input
              id="subject"
              type="text"
              placeholder="Subject line"
              autoFocus
              value={subject}
              onChange={(e) => setSubject(e.target.value)}
            />
          </Box>
        )}
        <Box mb={3}>
          <TextArea
            id="message"
            placeholder="Enter a message..."
            autoSize={{minRows: 4, maxRows: 6}}
            autoFocus
            value={message}
            onChange={(e) => setMessage(e.target.value)}
          />
        </Box>
      </Box>
    </Modal>
  );
};

const ButtonWrapper = ({
  isDisabled = false,
  disabledTooltipPlacement = 'left',
  disabledTooltipTitle = 'This customer already has an open conversation',
  onClick,
}: {
  isDisabled?: boolean;
  disabledTooltipPlacement?: TooltipPlacement;
  disabledTooltipTitle?: string;
  onClick: () => void;
}) => {
  const button = (
    <Button type="primary" onClick={onClick} disabled={isDisabled}>
      Start conversation
    </Button>
  );

  if (isDisabled) {
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

export type Props = {
  customerId: string;
  isDisabled?: boolean;
  disabledTooltipPlacement?: TooltipPlacement;
  disabledTooltipTitle?: string;
  onInitializeNewConversation?: (conservation: Conversation) => void;
};

export const StartConversationWrapper = ({
  children,
  customerId,
  onInitializeNewConversation,
}: {
  children: (handleOpenModal: () => void) => React.ReactElement;
  customerId: string;
  onInitializeNewConversation?: (conservation: Conversation) => void;
}) => {
  const [isModalOpen, setModalOpen] = React.useState(false);

  const handleOpenNewConversationModal = () => setModalOpen(true);
  const handleCloseNewConversationModal = () => setModalOpen(false);

  const initializeNewConversation = async (params: Record<any, any>) => {
    try {
      const conversation = await API.createNewConversation(customerId, params);

      if (onInitializeNewConversation) {
        onInitializeNewConversation(conversation);
      }
    } catch (err) {
      logger.error('Failed to initialize conversation!', err);
    }

    handleCloseNewConversationModal();
  };

  return (
    <React.Fragment>
      {children(handleOpenNewConversationModal)}

      <NewConversationModal
        visible={isModalOpen}
        onCancel={handleCloseNewConversationModal}
        onSuccess={initializeNewConversation}
      />
    </React.Fragment>
  );
};

export const StartConversationButton = ({
  customerId,
  isDisabled,
  disabledTooltipPlacement,
  disabledTooltipTitle,
  onInitializeNewConversation,
}: Props) => {
  return (
    <StartConversationWrapper
      customerId={customerId}
      onInitializeNewConversation={onInitializeNewConversation}
    >
      {(onClick) => (
        <ButtonWrapper
          isDisabled={isDisabled}
          disabledTooltipPlacement={disabledTooltipPlacement}
          disabledTooltipTitle={disabledTooltipTitle}
          onClick={onClick}
        />
      )}
    </StartConversationWrapper>
  );
};

export default StartConversationButton;
