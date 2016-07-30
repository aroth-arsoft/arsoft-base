#include "opts_helper.h"
#include <boost/algorithm/string/erase.hpp>
#include <boost/algorithm/string/regex.hpp>
#include <iomanip>

namespace
{
  const size_t LONG_NON_PREPENDED_IF_EXIST_ELSE_PREPENDED_SHORT = 0;
  const size_t LONG_PREPENDED_IF_EXIST_ELSE_PREPENDED_SHORT = 1;
  const size_t SHORT_PREPENDED_IF_EXIST_ELSE_LONG = 4;

  const size_t SHORT_OPTION_STRING_LENGTH = 2; // -x
  const size_t ADEQUATE_WIDTH_FOR_OPTION_NAME = 20;

  const bool HAS_ARGUMENT = true;
  const bool DOES_NOT_HAVE_ARGUMENT = false;

} // namespace

namespace arsoft
{
//---------------------------------------------------------------------------------------------------------------------
  CustomOptionDescription::CustomOptionDescription(boost::shared_ptr<boost::program_options::option_description> option) :
    required_(false),
    hasShort_(false),
    hasArgument_(false),
    isPositional_(false)
  {
    if ( (option->canonical_display_name(SHORT_PREPENDED_IF_EXIST_ELSE_LONG).size() == SHORT_OPTION_STRING_LENGTH ) )
    {
      hasShort_ = true;
      optionID_ = option->canonical_display_name(SHORT_PREPENDED_IF_EXIST_ELSE_LONG);
      optionDisplayName_ = option->canonical_display_name(SHORT_PREPENDED_IF_EXIST_ELSE_LONG);
    }
    else
    {
      hasShort_ = false;
      optionID_ = option->canonical_display_name(LONG_NON_PREPENDED_IF_EXIST_ELSE_PREPENDED_SHORT);
      optionDisplayName_ = option->canonical_display_name(LONG_PREPENDED_IF_EXIST_ELSE_PREPENDED_SHORT);
    }

    boost::shared_ptr<const boost::program_options::value_semantic> semantic = option->semantic();
    required_ = semantic->is_required();
    hasArgument_ = semantic->max_tokens() > 0 ? HAS_ARGUMENT : DOES_NOT_HAVE_ARGUMENT;

    optionDescription_ = option->description();
    optionFormatName_ = option->format_name();

  }

//---------------------------------------------------------------------------------------------------------------------
  void CustomOptionDescription::checkIfPositional(const boost::program_options::positional_options_description& positionalDesc)
  {
    for (size_t i = 0; i < positionalDesc.max_total_count(); ++i)
    {
      if (optionID_ == positionalDesc.name_for_position(i))
      {
        boost::algorithm::erase_all(optionDisplayName_, "-");
        isPositional_ = true;
        break;
      }

    } // for

  }

//---------------------------------------------------------------------------------------------------------------------
  std::string CustomOptionDescription::getOptionUsageString()
  {
    std::stringstream usageString;
    if ( isPositional_ )
    {
      usageString << "\t" << std::setw(ADEQUATE_WIDTH_FOR_OPTION_NAME) << std::left << optionDisplayName_ << "\t" << optionDescription_;
    }
    else
    {
      usageString << "\t" << std::setw(ADEQUATE_WIDTH_FOR_OPTION_NAME) << std::left << optionFormatName_ << "\t" << optionDescription_;
    }

    return usageString.str();

  }
//---------------------------------------------------------------------------------------------------------------------
  void OptionPrinter::addOption(const CustomOptionDescription& optionDesc)
  {
    optionDesc.isPositional_ ? positionalOptions_.push_back(optionDesc) : options_.push_back(optionDesc);

  }

//---------------------------------------------------------------------------------------------------------------------
  std::string OptionPrinter::usage()
  {
    std::stringstream usageDesc;
    /** simple flags that have a short version
     */
    bool firstShortOption = true;
    usageDesc << "[";
    for (std::vector<CustomOptionDescription>::iterator it = options_.begin();
         it != options_.end();
         ++it)
    {
      if ( it->hasShort_ && ! it->hasArgument_ && ! it->required_ )
      {
        if (firstShortOption)
        {
          usageDesc << "-";
          firstShortOption = false;
        }

        usageDesc << it->optionDisplayName_[1];
      }

    }
    usageDesc << "] ";

    /** simple flags that DO NOT have a short version
     */
    for (std::vector<CustomOptionDescription>::iterator it = options_.begin();
         it != options_.end();
         ++it)
    {
      if ( ! it->hasShort_ && ! it->hasArgument_ && ! it->required_ )
      {
        usageDesc << "[" << it->optionDisplayName_ << "] ";
      }

    }

    /** options with arguments
     */
    for (std::vector<CustomOptionDescription>::iterator it = options_.begin();
         it != options_.end();
         ++it)
    {
      if ( it->hasArgument_ && ! it->required_ )
      {
        usageDesc << "[" << it->optionDisplayName_ << " ARG] ";
      }

    }

    /** required options with arguments
     */
    for (std::vector<CustomOptionDescription>::iterator it = options_.begin();
         it != options_.end();
         ++it)
    {
      if ( it->hasArgument_ && it->required_ )
      {
        usageDesc << it->optionDisplayName_ << " ARG ";
      }

    }

    /** positional option
     */
    for (std::vector<CustomOptionDescription>::iterator it = positionalOptions_.begin();
         it != positionalOptions_.end();
         ++it)
    {
      usageDesc << it->optionDisplayName_ << " ";

    }

    return usageDesc.str();

  }

//---------------------------------------------------------------------------------------------------------------------
  std::string OptionPrinter::positionalOptionDetails()
  {
    std::stringstream output;
    for (std::vector<CustomOptionDescription>::iterator it = positionalOptions_.begin();
         it != positionalOptions_.end();
         ++it)
    {
      output << it->getOptionUsageString() << std::endl;
    }

    return output.str();
  }

//---------------------------------------------------------------------------------------------------------------------
  std::string OptionPrinter::optionDetails()
  {
    std::stringstream output;
    for (std::vector<CustomOptionDescription>::iterator it = options_.begin();
         it != options_.end();
         ++it)
    {
      output << it->getOptionUsageString() << std::endl;

    }

    return output.str();
  }

//---------------------------------------------------------------------------------------------------------------------
  void OptionPrinter::printStandardAppDesc(const std::string& appName,
                                           std::ostream& out,
                                           boost::program_options::options_description desc,
                                           boost::program_options::positional_options_description* positionalDesc)
  {
    OptionPrinter optionPrinter;

    typedef std::vector<boost::shared_ptr<boost::program_options::option_description > > Options;
    Options allOptions = desc.options();
    for (Options::iterator it = allOptions.begin();
         it != allOptions.end();
         ++it)
    {
      CustomOptionDescription currOption(*it);
      if ( positionalDesc )
      {
        currOption.checkIfPositional(*positionalDesc);
      }

      optionPrinter.addOption(currOption);

    } // foreach option

    out << "USAGE: " << appName << " " << optionPrinter.usage() << std::endl
        << std::endl;
    if(!optionPrinter.positionalOptionDetails().empty())
        out << "Positional arguments:" << std::endl << optionPrinter.positionalOptionDetails() << std::endl;
    if(!optionPrinter.optionDetails().empty())
        out << "Option Arguments: " << std::endl << optionPrinter.optionDetails() << std::endl;
  }

//---------------------------------------------------------------------------------------------------------------------
  void OptionPrinter::formatRequiredOptionError(boost::program_options::required_option& error)
  {
    std::string currOptionName = error.get_option_name();
    boost::algorithm::erase_regex(currOptionName, boost::regex("^-+"));
    error.set_option_name(currOptionName);

  }

//---------------------------------------------------------------------------------------------------------------------

} // namespace
