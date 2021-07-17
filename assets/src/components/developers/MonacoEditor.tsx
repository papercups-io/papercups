import React from 'react';
import * as monaco from 'monaco-editor';
import Editor, {EditorProps, BeforeMount, Monaco} from '@monaco-editor/react';

export const MonacoEditor = (props: EditorProps) => {
  const handleEditorChange = (value: string | undefined, event: any) => {
    // TODO
  };

  const handleEditorDidMount = (
    editor: monaco.editor.IStandaloneCodeEditor,
    monaco: Monaco
  ) => {
    // TODO
  };

  const handleEditorWillMount: BeforeMount = (monaco: Monaco) => {
    // TODO
  };

  const handleEditorValidation = (markers: monaco.editor.IMarker[]) => {
    // TODO
  };

  return (
    <Editor
      height="100%"
      defaultLanguage="javascript"
      theme="vs-dark"
      defaultValue="// some comment"
      onChange={handleEditorChange}
      onMount={handleEditorDidMount}
      beforeMount={handleEditorWillMount}
      onValidate={handleEditorValidation}
      {...props}
    />
  );
};

export default MonacoEditor;
