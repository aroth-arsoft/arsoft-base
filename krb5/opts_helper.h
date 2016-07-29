#pragma once

#include <boost/program_options.hpp>
#include <string>

namespace arsoft
{
  class CustomOptionDescription
  {
  public: // interface
    CustomOptionDescription(boost::shared_ptr<boost::program_options::option_description> option);

    void checkIfPositional(const boost::program_options::positional_options_description& positionalDesc);

    std::string getOptionUsageString();

  public: // data
    std::string optionID_;
    std::string optionDisplayName_;
    std::string optionDescription_;
    std::string optionFormatName_;

    bool required_;
    bool hasShort_;
    bool hasArgument_;
    bool isPositional_;


  };

  class OptionPrinter
  {
  public: // interface
    void addOption(const CustomOptionDescription& optionDesc);

    /** Print the single line application usage description */
    std::string usage();

    std::string positionalOptionDetails();
    std::string optionDetails();

  public: // static
    static void printStandardAppDesc(const std::string& appName,
                                     std::ostream& out,
                                     boost::program_options::options_description desc,
                                     boost::program_options::positional_options_description* positionalDesc=NULL);
    static void formatRequiredOptionError(boost::program_options::required_option& error);

  private: // data
    std::vector<CustomOptionDescription> options_;
    std::vector<CustomOptionDescription> positionalOptions_;

  };

} // namespace arsoft
