import React from 'react';
import {renderToStaticMarkup} from 'react-dom/server';
import {Box, Flex} from 'theme-ui';
// @ts-ignore
import {generateElement} from 'react-live';
import {Button, MarkdownRenderer, Title} from '../common';
import MonacoEditor from '../developers/MonacoEditor';
import {getIframeContents} from '../developers/email/html';
import {
  Layout,
  Container,
  Content,
  Body,
  Paragraph,
  H2,
  Variable,
} from '../developers/email/boilerplate';
import * as API from '../../api';
import logger from '../../logger';
import {RouteComponentProps} from 'react-router-dom';
import {MessageTemplate} from '../../types';
import {sleep} from '../../utils';

const MARKDOWN_CODE_VALUE = `
const Email = () => {
  return (
    <Layout background="#f9f9f9">
      <Container minWidth={320} maxWidth={640}>
        <Content bordered theme={{color: "#1890ff"}}>
          <Body>
            <Markdown source={__MARKDOWN__} />
          </Body>
        </Content>
      </Container>
    </Layout>
  );
};
`;

type Props = RouteComponentProps<{id: string}>;

type State = {
  isLoading: boolean;
  isSaving: boolean;
  template: MessageTemplate | null;
  mode: string;
  text: string;
  react: string;
  markdown: string;
  html: string;
  json: any;
};

export class MessageTemplateEditor extends React.Component<Props, State> {
  iframe: HTMLIFrameElement | null = null;
  monaco: any | null = null;

  state: State = {
    isLoading: true,
    isSaving: false,
    template: null,
    mode: 'react',
    text: '',
    react: '',
    markdown: '',
    html: '',
    json: {name: 'Alex', company: 'Papercups'},
  };

  async componentDidMount() {
    const {id} = this.props.match.params;
    const template = await API.fetchMessageTemplate(id);
    const {raw_html: html, react_js: react, plain_text: text} = template;

    this.setState({template, html, react, text, isLoading: false});
  }

  handleUpdateJson = (code?: string) => {
    if (!code) {
      return this.setState({json: {}});
    }

    try {
      this.setState({json: JSON.parse(code)});
    } catch (e) {
      //
    }
  };

  getHtmlInnerText = (html: string) => {
    // TODO: maybe try injecting into iframe?
    const el = document.createElement('html');
    el.innerHTML = html;
    const [body] = el.getElementsByTagName('body');
    // TODO: figure out a way to preserve whitespace better (e.g. line breaks between paragraphs)
    return body && body.innerText ? body.innerText.trim() : '';
  };

  handleUpdateReactIframe = async () => {
    const code = this.monaco?.getValue();
    const doc = this.iframe?.contentDocument;

    if (!code || !doc) {
      return;
    }

    try {
      // TODO: instead of importing from react-live, just copy the files over?
      const Element = generateElement(
        {
          code: code.replace('const Email = ', ''),
          scope: {
            Layout,
            Container,
            Content,
            Body,
            Paragraph,
            H2,
            Variable,
          },
        },
        logger.error
      );

      const html = renderToStaticMarkup(<Element />);
      const contents = getIframeContents({html});

      // const rendered = await API.renderEmailTemplate({
      //   html: contents,
      //   data: this.state.json,
      // });

      doc.open();
      doc.write(contents);
      doc.close();

      this.setState({
        react: code,
        html: contents,
        text: this.getHtmlInnerText(contents),
      });
    } catch (e) {
      logger.error(e);
    }
  };

  handleUpdateMarkdownIframe = async () => {
    const code = this.monaco?.getValue();
    const doc = this.iframe?.contentDocument;

    if (!code || !doc) {
      return;
    }

    try {
      // TODO: instead of importing from react-live, just copy the files over?
      const Element = generateElement(
        {
          code: MARKDOWN_CODE_VALUE.replace('const Email = ', ''),
          scope: {
            Layout,
            Container,
            Content,
            Body,
            Paragraph,
            H2,
            Variable,
            Markdown: MarkdownRenderer,
            __MARKDOWN__: code,
          },
        },
        logger.error
      );

      const html = renderToStaticMarkup(<Element />);
      const contents = getIframeContents({html});
      const rendered = await API.renderEmailTemplate({
        html: contents,
        data: this.state.json,
      });

      doc.open();
      doc.write(rendered);
      doc.close();

      this.setState({
        markdown: code,
        html: contents,
        text: this.getHtmlInnerText(contents),
      });
    } catch (e) {
      logger.error(e);
    }
  };

  getEmailText = (): string | null => {
    const [body] =
      this.iframe?.contentWindow?.document?.getElementsByTagName('body') ?? [];

    return body && body.innerText ? body.innerText.trim() : null;
  };

  handleEditorMounted = (editor: any) => {
    this.monaco = editor;

    if (this.state.mode === 'react') {
      this.handleUpdateReactIframe();
    } else {
      this.handleUpdateMarkdownIframe();
    }
  };

  handleSaveTemplate = async () => {
    try {
      this.setState({isSaving: true});

      const {id: templateId} = this.props.match.params;
      const {mode, react, text, html} = this.state;

      const template = await API.updateMessageTemplate(templateId, {
        name: 'August Product Update',
        plain_text: text,
        raw_html: html,
        react_js: react,
        type: mode,
      });

      this.setState({template});
    } catch (err) {
      logger.error('Error saving message template:', err);
    } finally {
      await sleep(2000);

      this.setState({isSaving: false});
    }

    // if (mode === 'react') {
    //   const result = await API.createMessageTemplate({
    //     name: 'Test template',
    //     plain_text: text,
    //     raw_html: html,
    //     react_js: react,
    //   });

    //   console.log('Result:', result);
    // } else {
    //   await API.createMessageTemplate({
    //     markdown,
    //     plain_text: text,
    //     raw_html: html,
    //   });
    // }
  };

  render() {
    const {template, react, markdown, isLoading, isSaving} = this.state;

    if (isLoading || !template) {
      return null;
    }

    const {name} = template;

    return (
      <Flex sx={{flex: 1, flexDirection: 'column'}}>
        <Flex
          p={3}
          sx={{
            justifyContent: 'space-between',
            alignItems: 'center',
            borderBottom: '1px solid rgba(0,0,0,.06)',
          }}
        >
          <Title level={4} style={{margin: 0}}>
            {name}
          </Title>
          {/* TODO: auto-save instead? */}
          <Button
            type="primary"
            loading={isSaving}
            onClick={this.handleSaveTemplate}
          >
            {isSaving ? 'Saving...' : 'Save template'}
          </Button>
        </Flex>

        <Flex sx={{width: '100%', flex: 1}}>
          <Flex sx={{flex: 1, flexDirection: 'column'}}>
            {this.state.mode === 'react' ? (
              <MonacoEditor
                height="100%"
                width="100%"
                defaultLanguage="javascript"
                defaultValue={react}
                onMount={this.handleEditorMounted}
                onValidate={this.handleUpdateReactIframe}
                onSave={this.handleUpdateReactIframe}
              />
            ) : (
              <MonacoEditor
                height="100%"
                width="100%"
                defaultLanguage="markdown"
                defaultValue={markdown}
                options={{tabSize: 2}}
                onMount={this.handleEditorMounted}
                onChange={this.handleUpdateMarkdownIframe}
                onValidate={this.handleUpdateMarkdownIframe}
                onSave={this.handleUpdateMarkdownIframe}
              />
            )}
          </Flex>
          <Flex sx={{flex: 1.2, flexDirection: 'column'}}>
            <Box sx={{flex: 1}}>
              <iframe
                title="email"
                style={{height: '100%', width: '100%', border: 'none'}}
                ref={(el) => (this.iframe = el)}
              />
            </Box>
          </Flex>
        </Flex>
      </Flex>
    );
  }
}

export default MessageTemplateEditor;
