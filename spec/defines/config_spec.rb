require 'spec_helper'

describe 'nginx::config' do
  let(:title) { 'foo' }

  context "with neither source or content specified" do
    it { is_expected.not_to compile }
  end

  context "with source and content both specified" do
    let(:params) {
      {
        :source  => 'puppet:///modules/test/home/foo.conf',
        :content => 'foo',
      }
    }

    it { is_expected.not_to compile }
  end

  context "with source specified" do
    let(:params) { {:source => 'puppet:///modules/test/home/foo.conf'} }

    it { is_expected.to compile }
    it { is_expected.to contain_nginx__config('foo') }
    it { is_expected.to contain_file('/etc/nginx/conf.d/foo.conf').with_source('puppet:///modules/test/home/foo.conf') }

    context "and custom path" do
      let(:params) {
        super().merge(
          :path => '/etc/nginx/my_config.conf',
        )
      }

      it { is_expected.to contain_file('/etc/nginx/my_config.conf').with_source('puppet:///modules/test/home/foo.conf') }
    end
  end

  context "with content specified" do
    let(:params) { {:content => 'some content'} }

    it { is_expected.to compile }
    it { is_expected.to contain_nginx__config('foo') }
    it { is_expected.to contain_file('/etc/nginx/conf.d/foo.conf').with_content('some content') }

    context "and custom path" do
      let(:params) {
        super().merge(
          :path => '/etc/nginx/my_config.conf',
        )
      }

      it { is_expected.to contain_file('/etc/nginx/my_config.conf').with_content('some content') }
    end
  end
end
