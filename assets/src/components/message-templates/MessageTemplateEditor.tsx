import React from 'react';
import {renderToStaticMarkup} from 'react-dom/server';
import {Link, RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import qs from 'query-string';
// @ts-ignore
import {generateElement} from 'react-live';

import {Button, Input, MarkdownRenderer, Select, Title} from '../common';
import MonacoEditor from '../developers/MonacoEditor';
import {getIframeContents} from '../developers/email/html';
import {
  Layout,
  Container,
  Content,
  Body,
  Paragraph,
  H1,
  H2,
  H3,
  Image,
  Variable,
} from '../developers/email/boilerplate';
import * as API from '../../api';
import logger from '../../logger';
import {MessageTemplate} from '../../types';
import {sleep} from '../../utils';
import {ArrowLeftOutlined} from '../icons';

const DEFAULT_MARKDOWN_VALUE = `
Hey {{name}}!

Papercups v2.0 is out! Here are the biggest changes...

## Slack Integration

Our Slack integration allows you to...

Best,
Papercups Team
`;

const DEFAULT_CODE_VALUE = `
const Email = () => {
  return (
    <Layout background="#f9f9f9">
      <Container minWidth={320} maxWidth={640}>
        <Content bordered theme={{color: "#1890ff"}}>
          <Body>
            <Paragraph>
              Hey <Variable template="<%= name %>" />!
            </Paragraph>
            <Paragraph>
              Papercups v2.0 is out! Here are the biggest changes...
            </Paragraph>

            <H2>
              Slack Integration
            </H2>
            <Paragraph>
              Our Slack integration allows you to...
            </Paragraph>
          </Body>
        </Content>
      </Container>
    </Layout>
  );
};
`;

const MARKDOWN_CODE_VALUE = `
const Email = () => {
  return <Markdown source={__MARKDOWN__} />;
};
`;

type TemplateMode = 'react' | 'markdown' | 'plain_text';

type Props = RouteComponentProps<{id: string}>;

type State = {
  isLoading: boolean;
  isSaving: boolean;
  broadcastId: string | null;
  template: MessageTemplate | null;
  subject: string;
  mode: TemplateMode;
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
    broadcastId: null,
    template: null,
    subject: '',
    mode: 'react',
    text: '',
    react: '',
    markdown: '',
    html: '',
    json: {name: 'Alex', company: 'Papercups'},
  };

  async componentDidMount() {
    const {id} = this.props.match.params;
    const q = qs.parse(this.props.location.search);
    const broadcastId = q.bid ? String(q.bid) : null;
    const template = await API.fetchMessageTemplate(id);
    const {
      raw_html: html,
      react_js: react,
      plain_text: text,
      default_subject: subject,
      markdown,
      type,
    } = template;

    this.setState({
      broadcastId,
      template,
      html,
      text,
      subject,
      mode: type,
      react: react || DEFAULT_CODE_VALUE,
      markdown: markdown || DEFAULT_MARKDOWN_VALUE,
      isLoading: false,
    });
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
            Image,
            H1,
            H2,
            H3,
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
        // TODO: make sure this is reliable
        text: this.getEmailText() || this.getHtmlInnerText(contents),
      });
    } catch (e) {
      logger.error(e);
    }
  };

  handleUpdatePlainTextIframe = async () => {
    const text = this.monaco?.getValue();
    const doc = this.iframe?.contentDocument;

    if (!text || !doc) {
      return;
    }

    try {
      // TODO: don't use an iframe for this?

      const contents = getIframeContents({
        html: `<main>${text}</main>`,
        cssPremailerIgnore: '',
        css: `main {
          padding: 40px;
          font-family: Arial, Helvetica, sans-serif;
          white-space: break-spaces;
          -webkit-font-smoothing: antialiased;
          -moz-osx-font-smoothing: grayscale;
        }`,
      });

      doc.open();
      doc.write(contents);
      doc.close();

      this.setState({text, html: contents});
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
            Markdown: MarkdownRenderer,
            __MARKDOWN__: code,
          },
        },
        logger.error
      );
      const html = renderToStaticMarkup(<Element />);
      const contents = getIframeContents({
        html,
        css: `
        .Text--markdown {
          padding: 40px;
          font-family: Arial, Helvetica, sans-serif;
          -webkit-font-smoothing: antialiased;
          -moz-osx-font-smoothing: grayscale;
        }`,
      });

      // const rendered = await API.renderEmailTemplate({
      //   html: contents,
      //   data: this.state.json,
      // });

      doc.open();
      doc.write(contents);
      doc.close();

      this.setState({
        markdown: code,
        html: html,
        // TODO: make sure this is reliable
        text: this.getEmailText() || this.getHtmlInnerText(contents),
      });
    } catch (e) {
      logger.error(e);
    }
  };

  getEmailText = (): string | null => {
    const [body] =
      this.iframe?.contentWindow?.document?.getElementsByTagName('body') ?? [];

    if (!body || !body.innerText) {
      return null;
    }

    return body.innerText
      .trim()
      .split('\n\n')
      .map((str) => str.trim())
      .join('\n\n');
  };

  handleEditorMounted = (editor: any) => {
    this.monaco = editor;

    switch (this.state.mode) {
      case 'react':
        return this.handleUpdateReactIframe();
      case 'markdown':
        return this.handleUpdateMarkdownIframe();
      case 'plain_text':
        return this.handleUpdatePlainTextIframe();
    }
  };

  handleChangeSubject = (e: React.ChangeEvent<HTMLInputElement>) => {
    this.setState({subject: e.target.value});
  };

  handleSaveTemplate = async () => {
    try {
      this.setState({isSaving: true});

      const {id: templateId} = this.props.match.params;
      const {
        mode,
        react,
        markdown,
        text,
        html,
        subject,
        broadcastId,
      } = this.state;

      const template = await API.updateMessageTemplate(templateId, {
        plain_text: text,
        raw_html: html,
        react_js: react,
        markdown: markdown,
        type: mode,
        default_subject: subject,
      });

      this.setState({template});

      if (broadcastId) {
        this.props.history.push(`/broadcasts/${broadcastId}`);
      }
    } catch (err) {
      logger.error('Error saving message template:', err);
    } finally {
      await sleep(2000);

      this.setState({isSaving: false});
    }
  };

  render() {
    const {
      mode,
      template,
      react,
      markdown,
      subject,
      isLoading,
      isSaving,
    } = this.state;

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
          <Flex sx={{alignItems: 'center'}}>
            <Box mr={4}>
              <Link to={`/message-templates${this.props.location.search}`}>
                <Button icon={<ArrowLeftOutlined />}>Back</Button>
              </Link>
            </Box>

            <Title level={4} style={{margin: 0}}>
              {name}
            </Title>
          </Flex>
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
          <Flex sx={{flex: 1, flexDirection: 'column', overflow: 'hidden'}}>
            <Box p={3}>
              <Select
                style={{width: '100%'}}
                placeholder="Select template mode"
                value={mode}
                onChange={(value: TemplateMode) => {
                  this.setState({mode: value});
                }}
                options={[
                  {value: 'react', display: 'ReactJS'},
                  {value: 'markdown', display: 'Markdown'},
                  // {value: 'react_markdown', display: 'ReactJS + Markdown'},
                  {value: 'plain_text', display: 'Plain text'},
                ].map(({value, display}) => {
                  return {id: value, key: value, label: display, value};
                })}
              />
            </Box>

            {{
              react: (
                <MonacoEditor
                  key={mode}
                  height="100%"
                  width="100%"
                  defaultLanguage="javascript"
                  defaultValue={react}
                  onMount={this.handleEditorMounted}
                  onValidate={this.handleUpdateReactIframe}
                  onSave={this.handleUpdateReactIframe}
                />
              ),
              markdown: (
                <MonacoEditor
                  key={mode}
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
              ),
              plain_text: (
                <MonacoEditor
                  key={mode}
                  height="100%"
                  width="100%"
                  defaultLanguage="text"
                  defaultValue={markdown}
                  options={{tabSize: 2}}
                  onMount={this.handleEditorMounted}
                  onChange={this.handleUpdatePlainTextIframe}
                  onValidate={this.handleUpdatePlainTextIframe}
                  onSave={this.handleUpdatePlainTextIframe}
                />
              ),
            }[mode] || null}
          </Flex>

          <Flex sx={{flex: 1.2, flexDirection: 'column'}}>
            <Box py={3} px={4}>
              <Input
                id="subject"
                type="text"
                placeholder="Subject line"
                value={subject}
                onChange={this.handleChangeSubject}
              />
            </Box>
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
